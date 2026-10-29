-- Migration 001: move recipe categories into their own table
--
-- Database: `recipe_db`
--
-- Before: recipes_flat.category holds the category name as text ('Chicken', 'Beef', ...)
-- After:  categories(id, name) holds each name once, and recipes_flat.category_id
--         points at it with a foreign key.
--
-- Run once, after importing schema.sql. MySQL commits each ALTER/CREATE
-- immediately, so take a backup (phpMyAdmin > Export) before running.

-- --------------------------------------------------------

--
-- 1. Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_categories_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- 2. Fill `categories` with every category name already used by a recipe
--

INSERT INTO `categories` (`name`)
SELECT DISTINCT TRIM(`category`)
FROM `recipes_flat`
WHERE `category` IS NOT NULL AND TRIM(`category`) <> ''
ORDER BY TRIM(`category`);

--
-- 3. Add `category_id` to `recipes_flat` and point each recipe at its category
--

ALTER TABLE `recipes_flat`
  ADD COLUMN `category_id` int(11) DEFAULT NULL AFTER `category`;

UPDATE `recipes_flat` r
INNER JOIN `categories` c ON c.`name` = TRIM(r.`category`)
SET r.`category_id` = c.`id`;

--
-- 4. Add the foreign key
--    ON DELETE RESTRICT: a category can't be deleted while recipes still use it.
--    ON UPDATE CASCADE:  if a category's id changes, recipes follow it.
--

ALTER TABLE `recipes_flat`
  ADD KEY `idx_recipes_flat_category_id` (`category_id`),
  ADD CONSTRAINT `fk_recipes_flat_category`
    FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

--
-- 5. Drop the old text column now that category_id replaces it
--

ALTER TABLE `recipes_flat`
  DROP COLUMN `category`;


-- --------------------------------------------------------
--
-- Rollback (run these by hand to undo this migration)
--
-- ALTER TABLE `recipes_flat` ADD COLUMN `category` varchar(255) DEFAULT NULL AFTER `subtitle`;
-- UPDATE `recipes_flat` r INNER JOIN `categories` c ON c.`id` = r.`category_id` SET r.`category` = c.`name`;
-- ALTER TABLE `recipes_flat` DROP FOREIGN KEY `fk_recipes_flat_category`;
-- ALTER TABLE `recipes_flat` DROP KEY `idx_recipes_flat_category_id`, DROP COLUMN `category_id`;
-- DROP TABLE `categories`;
