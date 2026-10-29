-- Normalized recipe schema
--
-- Database: `recipe_db`
-- Server version: MySQL 5.7
--
-- Replaces the single wide `recipes_flat` table with one table per group of
-- recipe information. Every table points back at `recipes`.`id`:
--
--   recipes          id (recipe primary key), image_folder, source_pdf
--   recipe_titles    title, slug, subtitle                         (1 row per recipe)
--   recipe_info      category, servings, description, main_image   (1 row per recipe)
--   ingredient_info  ingredients_image                             (1 row per recipe)
--   ingredients      one row per ingredient line                   (many per recipe)
--   tools            each tool stored once                         (shared by recipes)
--   recipe_tools     which recipe uses which tool                  (many per recipe)
--   tool_images      one row per tool image                        (many per recipe tool)
--   tips             tip_type, tip_title, tip_text, tip_image      (0 or more per recipe)
--   steps            one row per step                              (many per recipe)
--
-- ingredient_count and step_count are not stored. They are counted from the
-- rows in `ingredients` and `steps` by the `recipe_counts` view at the bottom,
-- so they can never disagree with the actual ingredients and steps.
--
-- Importing this file drops and recreates the tables listed above (including
-- `categories`, recreated with the same ids). `recipes_flat` is not touched.

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

DROP VIEW IF EXISTS `recipe_counts`;
DROP TABLE IF EXISTS `steps`, `tips`, `tool_images`, `recipe_tools`, `tools`,
  `ingredients`, `ingredient_info`, `recipe_info`, `recipe_titles`, `recipes`, `categories`;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_categories_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `recipes`
-- The recipe primary key. Every other recipe table references `recipes`.`id`.
-- image_folder and source_pdf (the "unsorted" fields) live here because each
-- recipe has exactly one of each.
--

CREATE TABLE `recipes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `image_folder` varchar(255) DEFAULT NULL,
  `source_pdf` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `recipe_titles`
--

CREATE TABLE `recipe_titles` (
  `recipe_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `slug` varchar(100) NOT NULL,
  `subtitle` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`recipe_id`),
  UNIQUE KEY `uq_recipe_titles_slug` (`slug`),
  CONSTRAINT `fk_recipe_titles_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `recipe_info`
--

CREATE TABLE `recipe_info` (
  `recipe_id` int(11) NOT NULL,
  `category_id` int(11) NOT NULL,
  `servings` tinyint(3) UNSIGNED NOT NULL,
  `description` text NOT NULL,
  `main_image` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`recipe_id`),
  KEY `idx_recipe_info_category_id` (`category_id`),
  CONSTRAINT `fk_recipe_info_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_recipe_info_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `ingredient_info`
-- The one ingredients photo per recipe. The ingredients themselves are rows in `ingredients`.
--

CREATE TABLE `ingredient_info` (
  `recipe_id` int(11) NOT NULL,
  `ingredients_image` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`recipe_id`),
  CONSTRAINT `fk_ingredient_info_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `ingredients`
-- One row per ingredient line (e.g. '¾ cup Jasmine Rice'). `position` keeps them in order.
--

CREATE TABLE `ingredients` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `recipe_id` int(11) NOT NULL,
  `position` tinyint(3) UNSIGNED NOT NULL,
  `ingredient` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ingredients_recipe_position` (`recipe_id`, `position`),
  CONSTRAINT `fk_ingredients_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `tools`
-- Each tool is stored once. Many recipes use the same tool (the Large Maple
-- Cutting Board is in 15), so `recipe_tools` links recipes to tools.
--

CREATE TABLE `tools` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tool_name` varchar(100) NOT NULL,
  `tool_brand` varchar(100) DEFAULT NULL,
  `tool_description` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tools_tool_name` (`tool_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `recipe_tools`
--

CREATE TABLE `recipe_tools` (
  `recipe_id` int(11) NOT NULL,
  `tool_id` int(11) NOT NULL,
  PRIMARY KEY (`recipe_id`, `tool_id`),
  KEY `idx_recipe_tools_tool_id` (`tool_id`),
  CONSTRAINT `fk_recipe_tools_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_recipe_tools_tool` FOREIGN KEY (`tool_id`) REFERENCES `tools` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `tool_images`
-- One row per tool image. The image files live in each recipe's own folder,
-- so an image belongs to a recipe's use of a tool, not to the tool alone.
--

CREATE TABLE `tool_images` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `recipe_id` int(11) NOT NULL,
  `tool_id` int(11) NOT NULL,
  `position` tinyint(3) UNSIGNED NOT NULL,
  `image` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tool_images_recipe_tool_position` (`recipe_id`, `tool_id`, `position`),
  CONSTRAINT `fk_tool_images_recipe_tool` FOREIGN KEY (`recipe_id`, `tool_id`)
    REFERENCES `recipe_tools` (`recipe_id`, `tool_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `tips`
-- Recipes without a tip simply have no row here.
--

CREATE TABLE `tips` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `recipe_id` int(11) NOT NULL,
  `tip_type` varchar(30) DEFAULT NULL,
  `tip_title` varchar(255) DEFAULT NULL,
  `tip_text` text,
  `tip_image` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_tips_recipe_id` (`recipe_id`),
  CONSTRAINT `fk_tips_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `steps`
-- One row per step, replacing step1_* ... step6_*. `step_number` is the "#",
-- so a recipe can have any number of steps.
--

CREATE TABLE `steps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `recipe_id` int(11) NOT NULL,
  `step_number` tinyint(3) UNSIGNED NOT NULL,
  `step_title` varchar(255) NOT NULL,
  `step_instructions` text NOT NULL,
  `step_image` varchar(255) DEFAULT NULL,
  `step_image_retina` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_steps_recipe_step_number` (`recipe_id`, `step_number`),
  CONSTRAINT `fk_steps_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `name`) VALUES
(1, 'Beef'),
(2, 'Chicken'),
(3, 'Fish & Seafood'),
(4, 'Pork'),
(5, 'Turkey'),
(6, 'Vegetarian');

--
-- Dumping data for table `recipes`
--

INSERT INTO `recipes` (`id`, `image_folder`, `source_pdf`) VALUES
(1, 'images/ancho-orange-chicken', 'Recipe_Ancho-Orange_Chicken_with_Kale_Rice_Roasted_Carrots.pdf'),
(2, 'images/beef-medallions-mushroom-sauce', 'Recipe_Beef_Medallions_Mushroom_Sauce_with_Mashed_Potatoes.pdf'),
(3, 'images/broccoli-basil-pesto-sandwiches', 'Recipe_Broccoli_Basil_Pesto_Sandwiches_with_Romaine_Citrus_Salad.pdf'),
(4, 'images/broccoli-mozzarella-calzones', 'Recipe_Broccoli_Mozzarella_Calzones_with_Caesar_Salad.pdf'),
(5, 'images/bucatini-alfredo', 'Recipe_Bucatini_Alfredo_with_Broccoli.pdf'),
(6, 'images/bucatini-tomato-sauce', 'Recipe_Bucatini_Tomato_Sauce_with_Roasted_Broccoli.pdf'),
(7, 'images/cheesy-enchiladas-rojas', 'Recipe_Cheesy_Enchiladas_Rojas_with_Mushrooms_Kale.pdf'),
(8, 'images/crispy-fish-sandwiches', 'Recipe_Crispy_Fish_Sandwiches_with_Tartar_Sauce_Roasted_Sweet_Potato_Wedges.pdf'),
(9, 'images/general-tsos-chicken', 'Recipe_General_Tsos_Chicken_with_Bok_Choy_Jasmine_Rice.pdf'),
(10, 'images/hoisin-glazed-pork-chops', 'Recipe_HoisinGlazed_Pork_Chops_with_StirFried_Vegetables_Wonton_Noodles.pdf'),
(11, 'images/honey-butter-barramundi', 'Recipe_HoneyButter_Barramundi_with_Zaatar_Roasted_Vegetables.pdf'),
(12, 'images/kale-ricotta-quiche', 'Recipe_Kale_Ricotta_Quiche_with_Romaine,_Apple,_Almond_Salad.pdf'),
(13, 'images/mexican-spiced-barramundi', 'Recipe_MexicanSpiced_Barramundi_with_Kale_Sweet_Potato_Avocado_Salad.pdf'),
(14, 'images/mushroom-potato-tacos', 'Recipe_Mushroom_Potato_Tacos_with_Romaine_Orange_Salad.pdf'),
(15, 'images/parmesan-crusted-chicken', 'Recipe_ParmesanCrusted_Chicken_with_Mashed_Sweet_Potatoes_Roasted_Broccoli.pdf'),
(16, 'images/pimento-cheeseburgers', 'Recipe_Pimento_Cheeseburgers_with_Sweet_Potato_Oven_Fries.pdf'),
(17, 'images/pork-chorizo-tacos', 'Recipe_Pork_Chorizo_Tacos_with_Cheesy_Roasted_Potatoes.pdf'),
(18, 'images/roasted-broccoli-fregola-sarda-salad', 'Recipe_Roasted_Broccoli_Fregola_Sarda_Salad_with_HardBoiled_Eggs_Tahini_Dressing.pdf'),
(19, 'images/roasted-brussels-sprout-freekeh-salad', 'Recipe_Roasted_Brussels_Sprout_Freekeh_Salad_with_Lemon_Yogurt_Barrel-Aged_Feta.pdf'),
(20, 'images/roasted-cauliflower-salad', 'Recipe_Roasted_Cauliflower_Salad_with_Caper_Brown_Butter_Parmesan_Breadcrumbs.pdf'),
(21, 'images/roasted-chicken-fall-vegetables', 'Recipe_Roasted_Chicken_Fall_Vegetables_with_Cranberry_Ginger_Compote.pdf'),
(22, 'images/roasted-pork-broccoli', 'Recipe_Roasted_Pork_Broccoli_with_Apple,_Cheese_Sauce,_Garlic_Breadcrumbs.pdf'),
(23, 'images/roasted-red-pepper-pasta', 'Recipe_Roasted_Red_Pepper_Pasta_with_LemonParmesan_Broccoli.pdf'),
(24, 'images/roasted-squash-curry', 'Recipe_Roasted_Squash_Curry_with_Crispy_Mung_Beans_Jasmine_Rice.pdf'),
(25, 'images/roasted-turkey-breast-farro-endive-salad', 'Recipe_Roasted_Turkey_Breast_FarroEndive_Salad_with_Brown_Butter_Apple_Compote.pdf'),
(26, 'images/salmon-honey-glazed-carrots', 'Recipe_Salmon_HoneyGlazed_Carrots_with_LemonSaffron_Yogurt_Sauce.pdf'),
(27, 'images/seared-chicken-mashed-potatoes', 'Recipe_Seared_Chicken_Mashed_Potatoes_with_MapleGlazed_Carrots.pdf'),
(28, 'images/seared-steaks-garlic-butter', 'Recipe_Seared_Steaks_Garlic_Butter_with_Oven_Fries.pdf'),
(29, 'images/shiitake-hoisin-beef-burgers', 'Recipe_Shiitake_Hoisin_Beef_Burgers_with_Miso_Mayonnaise_Roasted_Sweet_Potatoes.pdf'),
(30, 'images/shrimp-fra-diavolo', 'Recipe_Shrimp_Fra_Diavolo_with_Lumaca_Rigata_Pasta.pdf'),
(31, 'images/smoked-gouda-mushroom-flatbread', 'Recipe_Smoked_Gouda_Mushroom_Flatbread_with_Endive_Apple_Salad.pdf'),
(32, 'images/spicy-chicken-quesadillas', 'Recipe_Spicy_Chicken_Quesadillas_with_Beet_Orange_Salad.pdf'),
(33, 'images/spicy-pork-korean-rice-cakes', 'Recipe_Spicy_Pork_Korean_Rice_Cakes_with_Bok_Choy.pdf'),
(34, 'images/sweet-sour-vegetable-stir-fry', 'Recipe_Sweet_Sour_Vegetable_StirFry_with_Fried_Eggs_Peanuts.pdf'),
(35, 'images/thai-curry-chicken', 'Recipe_Thai_Curry_Chicken_with_Carrots_Bok_Choy.pdf'),
(36, 'images/tilapia-black-lentil-salad', 'Recipe_Tilapia_Black_Lentil_Salad_with_Lemon_Pan_Sauce.pdf'),
(37, 'images/togarashi-chicken-lettuce-cups', 'Recipe_Togarashi_Chicken_Lettuce_Cups_with_Orange_Radishes.pdf'),
(38, 'images/top-chef-ginger-marinated-grassfed-steaks', 'Recipe_Top_Chef_Ginger-Marinated_Grassfed_Steaks_with_Stir-Fried_Vegetables_Jasmine_RiceBlue_A.pdf'),
(39, 'images/top-chef-seared-grassfed-steaks', 'Recipe_Top_Chef_Seared_Grassfed_Steaks_with_Sweet_Chili-Glazed_Vegetables.pdf'),
(40, 'images/tuscan-chicken-green-lentil-stew', 'Recipe_Tuscan_Chicken_Green_Lentil_Stew_with_Goat_Cheese.pdf');

--
-- Dumping data for table `recipe_titles`
--

INSERT INTO `recipe_titles` (`recipe_id`, `title`, `slug`, `subtitle`) VALUES
(1, 'Ancho-Orange Chicken', 'ancho-orange-chicken', 'with Kale Rice & Roasted Carrots'),
(2, 'Beef Medallions & Mushroom Sauce', 'beef-medallions-mushroom-sauce', 'with Mashed Potatoes'),
(3, 'Broccoli & Basil Pesto Sandwiches', 'broccoli-basil-pesto-sandwiches', 'with Romaine & Citrus Salad'),
(4, 'Broccoli & Mozzarella Calzones', 'broccoli-mozzarella-calzones', 'with Caesar Salad'),
(5, 'Bucatini Alfredo', 'bucatini-alfredo', 'with Broccoli'),
(6, 'Bucatini & Tomato Sauce', 'bucatini-tomato-sauce', 'with Roasted Broccoli'),
(7, 'Cheesy Enchiladas Rojas', 'cheesy-enchiladas-rojas', 'with Mushrooms & Kale'),
(8, 'Crispy Fish Sandwiches', 'crispy-fish-sandwiches', 'with Tartar Sauce & Roasted Sweet Potato Wedges'),
(9, 'General Tso\'s Chicken', 'general-tsos-chicken', 'with Bok Choy & Jasmine Rice'),
(10, 'Hoisin-Glazed Pork Chops', 'hoisin-glazed-pork-chops', 'with Stir-Fried Vegetables & Wonton Noodles'),
(11, 'Honey-Butter Barramundi', 'honey-butter-barramundi', 'with Za\'atar Roasted Vegetables'),
(12, 'Kale & Ricotta Quiche', 'kale-ricotta-quiche', 'with Romaine, Apple, & Almond Salad'),
(13, 'Mexican-Spiced Barramundi', 'mexican-spiced-barramundi', 'with Kale, Sweet Potato, & Avocado Salad'),
(14, 'Mushroom & Potato Tacos', 'mushroom-potato-tacos', 'with Romaine & Orange Salad'),
(15, 'Parmesan-Crusted Chicken', 'parmesan-crusted-chicken', 'with Mashed Sweet Potatoes & Roasted Broccoli'),
(16, 'Pimento Cheeseburgers', 'pimento-cheeseburgers', 'with Sweet Potato Oven Fries'),
(17, 'Pork Chorizo Tacos', 'pork-chorizo-tacos', 'with Cheesy Roasted Potatoes'),
(18, 'Roasted Broccoli & Fregola Sarda Salad', 'roasted-broccoli-fregola-sarda-salad', 'with Hard-Boiled Eggs & Tahini Dressing'),
(19, 'Roasted Brussels Sprout & Freekeh Salad', 'roasted-brussels-sprout-freekeh-salad', 'with Lemon Yogurt & Barrel-Aged Feta'),
(20, 'Roasted Cauliflower Salad', 'roasted-cauliflower-salad', 'with Caper Brown Butter & Parmesan Breadcrumbs'),
(21, 'Roasted Chicken & Fall Vegetables', 'roasted-chicken-fall-vegetables', 'with Cranberry & Ginger Compote'),
(22, 'Roasted Pork & Broccoli', 'roasted-pork-broccoli', 'with Apple, Cheese Sauce, & Garlic Breadcrumbs'),
(23, 'Roasted Red Pepper Pasta', 'roasted-red-pepper-pasta', 'with Lemon-Parmesan Broccoli'),
(24, 'Roasted Squash Curry', 'roasted-squash-curry', 'with Crispy Mung Beans & Jasmine Rice'),
(25, 'Roasted Turkey Breast & Farro-Endive Salad', 'roasted-turkey-breast-farro-endive-salad', 'with Brown Butter Apple Compote'),
(26, 'Salmon & Honey-Glazed Carrots', 'salmon-honey-glazed-carrots', 'with Lemon-Saffron Yogurt Sauce'),
(27, 'Seared Chicken & Mashed Potatoes', 'seared-chicken-mashed-potatoes', 'with Maple-Glazed Carrots'),
(28, 'Seared Steaks & Garlic Butter', 'seared-steaks-garlic-butter', 'with Oven Fries'),
(29, 'Shiitake & Hoisin Beef Burgers', 'shiitake-hoisin-beef-burgers', 'with Miso Mayonnaise & Roasted Sweet Potatoes'),
(30, 'Shrimp Fra Diavolo', 'shrimp-fra-diavolo', 'with Lumaca Rigata Pasta'),
(31, 'Smoked Gouda & Mushroom Flatbread', 'smoked-gouda-mushroom-flatbread', 'with Endive & Apple Salad'),
(32, 'Spicy Chicken Quesadillas', 'spicy-chicken-quesadillas', 'with Beet & Orange Salad'),
(33, 'Spicy Pork & Korean Rice Cakes', 'spicy-pork-korean-rice-cakes', 'with Bok Choy'),
(34, 'Sweet & Sour Vegetable Stir-Fry', 'sweet-sour-vegetable-stir-fry', 'with Fried Eggs & Peanuts'),
(35, 'Thai Curry Chicken', 'thai-curry-chicken', 'with Carrots & Bok Choy'),
(36, 'Tilapia & Black Lentil Salad', 'tilapia-black-lentil-salad', 'with Lemon Pan Sauce'),
(37, 'Togarashi Chicken Lettuce Cups', 'togarashi-chicken-lettuce-cups', 'with Orange & Radishes'),
(38, 'Top Chef Ginger-Marinated Grassfed Steaks', 'top-chef-ginger-marinated-grassfed-steaks', 'with Stir-Fried Vegetables & Jasmine Rice'),
(39, 'Top Chef Seared Grassfed Steaks', 'top-chef-seared-grassfed-steaks', 'with Sweet Chili-Glazed Vegetables'),
(40, 'Tuscan Chicken & Green Lentil Stew', 'tuscan-chicken-green-lentil-stew', 'with Goat Cheese');

--
-- Dumping data for table `recipe_info`
--

INSERT INTO `recipe_info` (`recipe_id`, `category_id`, `servings`, `description`, `main_image`) VALUES
(1, 2, 4, 'We\'re amping up chicken breasts with a glaze of smoky ancho chile paste and fresh orange juice in this recipe. On the side, roasted carrots and lightly creamy, golden raisin-studded rice perfectly accent the sweetness of the glaze.', 'images/ancho-orange-chicken/dish.jpg'),
(2, 1, 2, 'In this easy recipe, inspired by steak Diane (an American restaurant classic), we\'re searing beef medallions, then using the fond in the pan to make a rich, bright mushroom sauce for spooning on top. Garlic mashed potatoes and sautéed kale make for delicious, simple sides.', 'images/beef-medallions-mushroom-sauce/dish.jpg'),
(3, 6, 4, 'These Italian focaccia sandwiches are layered with broccoli, three cheeses, and a savory basil, cashew, and pine nut pesto, then baked in the oven to meld all the bright, aromatic flavors. On the side, we\'re serving a refreshing salad of romaine and seasonal clementine, dressed in a creamy dressing made with fresh clementine juice.', 'images/broccoli-basil-pesto-sandwiches/dish.jpg'),
(4, 6, 4, 'These calzones are loaded with melty fresh mozzarella, creamy ricotta, and tender broccoli—balanced by a tangy tomato dipping sauce. For a refreshing side, we\'re tossing crunchy romaine and briny black olives in our take on Caesar dressing.', 'images/broccoli-mozzarella-calzones/dish.jpg'),
(5, 6, 2, 'This quick-cooking recipe captures all the deliciously creamy, rich flavor of the classic Italian-American sauce—with the welcome addition of quick-braised broccoli. A dusting of pecorino cheese completes each bowl with a touch of sharpness.', 'images/bucatini-alfredo/dish.jpg'),
(6, 6, 2, 'Made with petite datterini tomatoes, the sauce for tonight\'s bucatini highlights briny olives and capers, hot red pepper flakes, and savory Grana Padano cheese. We\'re mixing in roasted broccoli for contrasting texture and nutty-sweet flavor.', 'images/bucatini-tomato-sauce/dish.jpg'),
(7, 6, 4, 'Our hearty vegetarian enchiladas are filled with a combination of fragrant, Mexican-spiced rice and sautéed mushrooms and kale. For even more flavor, we\'re baking them under a smoky-sweet tomato sauce flavored with ancho chile paste and a layer of melty white cheddar. A dollop of lime-seasoned sour cream adds creamy, cooling balance. (You may receive green curly, dark green lacinato, or red kale.)', 'images/cheesy-enchiladas-rojas/dish.jpg'),
(8, 3, 4, 'These sandwiches highlight wild Alaskan pollock—flavored with aromatic seasonings, coated with panko breadcrumbs, and pan-fried for a golden-brown crust. In classic fashion, a tangy, mayo-based tartar sauce perfectly balances the fish.', 'images/crispy-fish-sandwiches/dish.jpg'),
(9, 2, 2, 'In this quick-cooking spin on a takeout favorite, hoisin sauce, honey, sriracha, and sesame oil lend our chicken the sweet, spicy, and nutty flavors General Tso\'s is known for. A light dusting of cornstarch on the chicken just before it hits the pan creates a delicately crispy exterior (and helps it soak up the irresistible sauce later).', 'images/general-tsos-chicken/dish.jpg'),
(10, 4, 4, 'Delightfully chewy wonton noodles tossed in a nutty, savory sauce are a delicious accompaniment to these pork chops. For depth of flavor, we\'re pan-searing the pork chops, then glazing them with barbecue-like hoisin, whose sweetness perfectly matches bites of sautéed carrots in the noodles.', 'images/hoisin-glazed-pork-chops/dish.jpg'),
(11, 3, 4, 'This Middle Eastern recipe pairs crispy barramundi—served in a family-friendly pan sauce of honey and butter—with a medley of winter vegetables. For savory, herby flavor, we\'re seasoning the vegetables with za\'atar before roasting them.', 'images/honey-butter-barramundi/dish.jpg'),
(12, 6, 4, 'This crowd-pleasing quiche showcases a rich, eggy filling made with ricotta and cream —balanced by hearty sautéed kale. On the side, we\'re serving a refreshing salad of crisp romaine and apple, wrapped in a creamy lemon dressing.', 'images/kale-ricotta-quiche/dish.jpg'),
(13, 3, 2, 'This recipe has been approved by Whole30®. To learn more about their guidelines, visit Whole30.com. We\'re partnering with Whole30® to bring you the first of eight weeks of delicious recipes. Zesty spiced barramundi is the perfect partner for a salad of roasted sweet potato and kale, marinated in a creamy avocado and citrus dressing to soften the leaves.', 'images/mexican-spiced-barramundi/dish.jpg'),
(14, 6, 2, 'For this hearty vegetarian meal, we\'re filling soft flour tortillas with mushrooms and potato—seasoned with a zesty, chorizo-inspired blend, then roasted. A pickled pepper relish lends bright flavor to the tacos, all tied together with a creamy sauce seasoned with the same spices. Our side salad of juicy orange and crunchy romaine rounds out the dish.', 'images/mushroom-potato-tacos/dish.jpg'),
(15, 2, 4, 'In this simple, seasonal recipe, you\'ll coat chicken in a combination of flour, parmesan cheese, and savory spices before pan-searing it. We\'re adding more of the same spices to a bright, creamy sauce, perfect for spooning over the chicken and broccoli.', 'images/parmesan-crusted-chicken/dish.jpg'),
(16, 1, 2, 'Tonight, the classic cheeseburger gets an easy, Southern-style lift from pimento cheese —a zesty spread made with cheddar, mayo, pickled peppers, and spices. We\'re serving our burgers with sweet potato oven fries for a flavorful, seasonal twist on the usual side.', 'images/pimento-cheeseburgers/dish.jpg'),
(17, 4, 2, 'These tacos get plenty of bold flavor from ground chorizo (a type of spiced pork sausage), cooked into a delightfully saucy filling with cabbage and fresh citrus juices. On the side, we\'re livening up roasted potatoes with garlic and Cotija cheese.', 'images/pork-chorizo-tacos/dish.jpg'),
(18, 6, 2, 'This Middle Eastern-inspired recipe is brimming with varied flavors and textures. Toasty pearls of pasta, roasted vegetables (seasoned with savory, herby za\'atar), crumbled cheese, and chopped almonds all come together in a smooth, nutty dressing.', 'images/roasted-broccoli-fregola-sarda-salad/dish.jpg'),
(19, 6, 2, 'This Mediterranean-inspired grain salad is brimming with varied, vibrant flavors. Nutty freekeh and roasted Brussels sprouts get pops of sweetness from pickled peppers and dates, balanced by briny crumbled Feta. To dollop on top, we\'re serving lemon-seasoned yogurt for extra brightness.', 'images/roasted-brussels-sprout-freekeh-salad/dish.jpg'),
(20, 6, 2, 'Seasonal salads don\'t get much more satisfying than this. We\'re bringing roasted cauliflower and sautéed kale together with cheesy toasted breadcrumbs and a briny caper-studded dressing. Served on top, soft-boiled eggs add extra richness.', 'images/roasted-cauliflower-salad/dish.jpg'),
(21, 2, 4, 'For this comforting autumn dinner, we\'re seasoning half chickens with the classic flavors of garlic, onion, and smoked paprika, then roasting them along with sweet potatoes and Brussels sprouts. The rich chicken finds delicious contrast in a tart-sweet compote, made simply by cooking fresh cranberries and ginger with a bit of sugar and water.', 'images/roasted-chicken-fall-vegetables/dish.jpg'),
(22, 4, 2, 'To elevate the classic savory-sweet pairing, we\'re topping roasted pork with sautéed apple in this crowd-pleasing recipe. The pork and a side of broccoli, roasted on the same sheet pan, come together with a rich, warming fontina cheese sauce.', 'images/roasted-pork-broccoli/dish.jpg'),
(23, 6, 2, 'In this quick-cooking recipe, whole grain pipe rigate gets pops of flavor from sweet roasted piquillo peppers and briny capers—plus a layer of exciting crunch from almonds. It all comes together in a creamy, mildly spicy sauce.', 'images/roasted-red-pepper-pasta/dish.jpg'),
(24, 6, 2, 'In this recipe, veggie curry gets a unique lift from spaghetti squash—oven-roasted, then broken into pasta-like strands with a fork. We\'re finishing our squash and bok choy in a sauce made with fresh aromatics and two well-balanced pantry ingredients: spicy yellow curry paste and cooling coconut milk. A garnish of dried mung beans brings it all together with exciting crunch.', 'images/roasted-squash-curry/dish.jpg'),
(25, 5, 2, 'Fall comfort food gets a delicious lift in this recipe. A sweet, toasty compote (simply apple and shallot cooked in brown butter) balances our savory roasted turkey breast. On the side, we\'re tossing warm grains with endive—first cooked with a bit of honey and lemon to brighten its mildly bitter flavor.', 'images/roasted-turkey-breast-farro-endive-salad/dish.jpg'),
(26, 3, 2, 'This elegant dish gets unique flavor from a prized spice, saffron, used two ways: added to the water used to boil the potatoes and stirred into a creamy yogurt sauce. The bright sauce is delicious spooned over rich salmon, potatoes, and carrots—which get another flavor-packed lift from a glaze of honey and fragrant cumin. Aleppo pepper adds just a hint of spice throughout the dish, balanced by cooling fresh mint.', 'images/salmon-honey-glazed-carrots/dish.jpg'),
(27, 2, 2, 'We\'re giving seared chicken a lift with a rich pan sauce, made with sweet maple syrup and tangy sherry vinegar. It\'s the perfect accompaniment for creamy mashed potatoes and roasted carrots, dressed with a bit more maple syrup.', 'images/seared-chicken-mashed-potatoes/dish.jpg'),
(28, 1, 4, '"Steak frites," or steak with french fries, is classic French bistro fare. Tonight\'s steaks get another layer of rich flavor from garlic butter, spooned over them as they cook. Creamy mustard sauce is a perfect match for the rich steaks and hearty oven-roasted fries, while a simple salad adds refreshing contrast. (You may receive crisp romaine or tender butter lettuce.)', 'images/seared-steaks-garlic-butter/dish.jpg'),
(29, 1, 4, 'These Asian-inspired burgers get their irresistible umami flavor from chopped shiitake mushrooms (mixed right into the beef) and a miso-mayo spread. Piled on top, crisp ribbons of bok choy round out the burgers, served with a side of roasted sweet potato wedges.', 'images/shiitake-hoisin-beef-burgers/dish.jpg'),
(30, 3, 2, 'Tonight\'s variation on the beloved Italian-American dish gets its "devilish" heat from Calabrian chile paste, mixed into a tangy-sweet tomato sauce. It perfectly coats shrimp, cabbage, and lumaca rigata pasta. A garnish of sliced almonds finishes the dish with contrasting crunch.', 'images/shrimp-fra-diavolo/dish.jpg'),
(31, 6, 2, 'For this rustic seasonal meal, we\'re topping flatbread—made by rolling out pizza dough until extra-thin—with two kinds of cheeses, including nutty smoked Gouda. Cremini mushrooms add even more irresistibly savory flavor to the flatbread, balanced by a bright, crisp endive and apple salad.', 'images/smoked-gouda-mushroom-flatbread/dish.jpg'),
(32, 2, 2, 'A seasonal salad of striped Chioggia beet, juicy orange, and peanuts is a fresh pairing for these zesty quesadillas. We\'re seasoning the chicken filling with both jalapeño pepper and Mexican spices—balanced by a layer of melty white cheddar. Mexican crema brightened up with lime juice is perfect for dipping.', 'images/spicy-chicken-quesadillas/dish.jpg'),
(33, 4, 4, 'In this crowd-pleasing recipe, a savory and spicy sauce (balanced by a touch of cooling crème fraîche) brings together ground pork, bok choy, and aromatics. We\'re mixing in delightfully chewy tteok, or rice cakes—a staple of Korean cuisine.', 'images/spicy-pork-korean-rice-cakes/dish.jpg'),
(34, 6, 2, 'Two kinds of citrus—seasonal orange and lemon—give the sauce for our stir-fried vegetables its irresistible sweet-sour balance. The carrots, celery, and bok choy perfectly contrast a rich fried egg and fluffy, radish-studded white rice.', 'images/sweet-sour-vegetable-stir-fry/dish.jpg'),
(35, 2, 2, 'In tonight\'s dish, the spicy and aromatic flavors of yellow curry paste—a Thai staple— shine through a lightly sweet coconut milk broth. Sautéed chicken, carrots, and bok choy give the curry plenty of hearty texture, while fluffy rice eagerly soaks up all the complex flavors. (Chefs, this curry paste packs a punch of heat, so be sure to use only as much as you\'d like!)', 'images/thai-curry-chicken/dish.jpg'),
(36, 3, 2, 'In this dish, we\'re putting a twist on Italian gremolata: adding pickled peppers to the classic parsley, garlic, and lemon condiment. The bright, tangy flavors perk up a hearty salad of black lentils and roasted broccoli. We\'re also using lemon juice as the base for an easy pan sauce to serve over our seared tilapia.', 'images/tilapia-black-lentil-salad/dish.jpg'),
(37, 2, 2, 'This recipe has been approved by Whole30®. To learn more about their guidelines, visit Whole30.com. We\'re partnering with Whole30® to bring you the first of eight weeks of delicious recipes. These chicken lettuce cups get their dynamic flavor from togarashi seasoning—a staple of Japanese cuisine. Juicy bites of orange add more bright flavor and color.', 'images/togarashi-chicken-lettuce-cups/dish.jpg'),
(38, 1, 2, 'In this recipe—inspired by our Quickfire Challenge from Top Chef Season 15 on Bravo—we\'re marinating grassfed steaks in fresh ginger, soy sauce, and citrusy ponzu sauce. The extra marinade transforms into an easy pan sauce, which adds punchy flavor to the steaks and a side of jasmine rice.', 'images/top-chef-ginger-marinated-grassfed-steaks/dish.jpg'),
(39, 1, 4, 'In this recipe, inspired by our Quickfire Challenge from Top Chef Season 15 on Bravo, simple grassfed steaks and rice get a sweet, tart, and spicy lift from glazed mushrooms and bok choy. Sliced radishes, softened a bit with lime juice, finish the dish off with subtle crunch.', 'images/top-chef-seared-grassfed-steaks/dish.jpg'),
(40, 2, 2, 'In this comforting cold-weather recipe, we\'re serving Tuscan-spiced chicken over tender green lentils and vegetables cooked in a light, savory tomato broth. Capers and crushed red pepper add briny flavor and a touch of heat to cut through the rich, earthy stew. (Chefs, rinsing the lentils after cooking removes excess starch, resulting in a more delicate flavor.)', 'images/tuscan-chicken-green-lentil-stew/dish.jpg');

--
-- Dumping data for table `ingredient_info`
--

INSERT INTO `ingredient_info` (`recipe_id`, `ingredients_image`) VALUES
(1, 'images/ancho-orange-chicken/ingredients.png'),
(2, 'images/beef-medallions-mushroom-sauce/ingredients.png'),
(3, 'images/broccoli-basil-pesto-sandwiches/ingredients.png'),
(4, 'images/broccoli-mozzarella-calzones/ingredients.png'),
(5, 'images/bucatini-alfredo/ingredients.png'),
(6, 'images/bucatini-tomato-sauce/ingredients.png'),
(7, 'images/cheesy-enchiladas-rojas/ingredients.png'),
(8, 'images/crispy-fish-sandwiches/ingredients.png'),
(9, 'images/general-tsos-chicken/ingredients.png'),
(10, 'images/hoisin-glazed-pork-chops/ingredients.png'),
(11, 'images/honey-butter-barramundi/ingredients.png'),
(12, 'images/kale-ricotta-quiche/ingredients.png'),
(13, 'images/mexican-spiced-barramundi/ingredients.png'),
(14, 'images/mushroom-potato-tacos/ingredients.png'),
(15, 'images/parmesan-crusted-chicken/ingredients.png'),
(16, 'images/pimento-cheeseburgers/ingredients.png'),
(17, 'images/pork-chorizo-tacos/ingredients.png'),
(18, 'images/roasted-broccoli-fregola-sarda-salad/ingredients.png'),
(19, 'images/roasted-brussels-sprout-freekeh-salad/ingredients.png'),
(20, 'images/roasted-cauliflower-salad/ingredients.png'),
(21, 'images/roasted-chicken-fall-vegetables/ingredients.png'),
(22, 'images/roasted-pork-broccoli/ingredients.png'),
(23, 'images/roasted-red-pepper-pasta/ingredients.png'),
(24, 'images/roasted-squash-curry/ingredients.png'),
(25, 'images/roasted-turkey-breast-farro-endive-salad/ingredients.png'),
(26, 'images/salmon-honey-glazed-carrots/ingredients.png'),
(27, 'images/seared-chicken-mashed-potatoes/ingredients.png'),
(28, 'images/seared-steaks-garlic-butter/ingredients.png'),
(29, 'images/shiitake-hoisin-beef-burgers/ingredients.png'),
(30, 'images/shrimp-fra-diavolo/ingredients.png'),
(31, 'images/smoked-gouda-mushroom-flatbread/ingredients.png'),
(32, 'images/spicy-chicken-quesadillas/ingredients.png'),
(33, 'images/spicy-pork-korean-rice-cakes/ingredients.png'),
(34, 'images/sweet-sour-vegetable-stir-fry/ingredients.png'),
(35, 'images/thai-curry-chicken/ingredients.png'),
(36, 'images/tilapia-black-lentil-salad/ingredients.png'),
(37, 'images/togarashi-chicken-lettuce-cups/ingredients.png'),
(38, 'images/top-chef-ginger-marinated-grassfed-steaks/ingredients.png'),
(39, 'images/top-chef-seared-grassfed-steaks/ingredients.png'),
(40, 'images/tuscan-chicken-green-lentil-stew/ingredients.png');

--
-- Dumping data for table `ingredients`
--

INSERT INTO `ingredients` (`recipe_id`, `position`, `ingredient`) VALUES
(1, 1, '¾ cup Jasmine Rice'),
(1, 2, '¾ lb Carrots'),
(1, 3, '2 cloves Garlic'),
(1, 4, '1 bunch Kale'),
(1, 5, '1 Lime'),
(1, 6, '1 Orange'),
(1, 7, '2 Tbsps Butter'),
(1, 8, '4 Boneless, Skinless Chicken Breasts'),
(1, 9, '1 Tbsp Ancho Chile Paste'),
(1, 10, '2 Tbsps Crème Fraîche'),
(1, 11, '3 Tbsps Golden Raisins'),
(2, 1, '2 Beef Medallions'),
(2, 2, '2 cloves Garlic'),
(2, 3, '1 Shallot'),
(2, 4, '1 bunch Kale'),
(2, 5, '2 Tbsps Butter'),
(2, 6, '1 Tbsp Dijon Mustard'),
(2, 7, '2 Tbsps Verjus Blanc'),
(2, 8, '4 oz Cremini Mushrooms'),
(2, 9, '¾ lb Yukon Gold Potatoes'),
(3, 1, '2 oz Asiago Cheese'),
(3, 2, '1 Piece Focaccia Bread'),
(3, 3, '1 8-Ounce Can Tomato Sauce'),
(3, 4, '½ lb Fresh Mozzarella Cheese'),
(3, 5, '2 Clementines'),
(3, 6, '2 cloves Garlic'),
(3, 7, '2 Romaine Lettuce Hearts'),
(3, 8, '1 lb Broccoli'),
(3, 9, '1 oz Golden Or Red Sweet Piquante Peppers'),
(3, 10, '2 Tbsps Crème Fraîche'),
(3, 11, '1 Tbsp Dijon Mustard'),
(3, 12, '½ cup Basil & Cashew Pesto (Contains Pine Nuts)'),
(3, 13, '⅓ cup Shaved Parmesan Cheese'),
(3, 14, '1 Tbsp Italian Seasoning (Whole Dried Basil, Sage, Oregano, Savory, Rosemary, Thyme, & Marjoram)'),
(4, 1, '2 Tbsps Mayonnaise'),
(4, 2, '1½ lbs Pizza Dough'),
(4, 3, '3 cloves Garlic'),
(4, 4, '1 Romaine Lettuce Heart'),
(4, 5, '1 lb Broccoli'),
(4, 6, '1 cup Part-Skim Ricotta Cheese'),
(4, 7, '1 8-Ounce Can Tomato Sauce'),
(4, 8, '½ lb Fresh Mozzarella Cheese'),
(4, 9, '¼ cup Grated Parmesan Cheese'),
(4, 10, '2 oz Black Cerignola Olives'),
(4, 11, '1 Tbsp Italian Seasoning (Whole Dried Basil, Sage, Oregano, Savory, Rosemary, Thyme, & Marjoram)'),
(4, 12, '1 Lemon'),
(5, 1, '6 oz Bucatini Pasta'),
(5, 2, '½ lb Broccoli'),
(5, 3, '2 cloves Garlic'),
(5, 4, '¼ cup Heavy Cream'),
(5, 5, '2 Tbsps Verjus Blanc'),
(5, 6, '2 Tbsps Crème Fraîche'),
(5, 7, '¼ tsp Crushed Red Pepper Flakes'),
(5, 8, '3 Tbsps All-Purpose Flour'),
(5, 9, '¼ cup Grated Pecorino Cheese'),
(6, 1, '6 oz Bucatini Pasta'),
(6, 2, '1 14-Ounce Can Datterini Tomatoes'),
(6, 3, '2 cloves Garlic'),
(6, 4, '2 Tbsps Butter'),
(6, 5, '1 Tbsp Capers'),
(6, 6, '1 lb Broccoli'),
(6, 7, '¾ oz Grana Padano Cheese'),
(6, 8, '1 oz Kalamata Olives'),
(6, 9, '¼ tsp Crushed Red Pepper Flakes'),
(6, 10, '1 Tbsp Italian Seasoning (Whole Dried Basil, Sage, Oregano, Savory, Rosemary, Thyme, & Marjoram)'),
(7, 1, '1 bunch Kale'),
(7, 2, '1 Lime'),
(7, 3, '8 Flour Tortillas'),
(7, 4, '¾ cup Jasmine Rice'),
(7, 5, '1 28-Ounce Can Whole Peeled Tomatoes'),
(7, 6, '4 oz Cremini Mushrooms'),
(7, 7, '3 cloves Garlic'),
(7, 8, '1 Yellow Onion'),
(7, 9, '1 bunch Chives'),
(7, 10, '2 Tbsps Ancho Chile Paste'),
(7, 11, '1 Tbsp Mexican Spice Blend (Ancho Chile Powder, Sweet Paprika, Garlic Powder, Ground Cumin, & Whole Mexican Oregano)'),
(7, 12, '½ lb White Cheddar Cheese'),
(7, 13, '½ cup Sour Cream'),
(8, 1, '1½ lbs Sweet Potatoes'),
(8, 2, '4 Potato Rolls'),
(8, 3, '¼ cup Mayonnaise'),
(8, 4, '21 oz Wild Alaskan Pollock Fillets'),
(8, 5, '2 Cage-Free Farm Eggs'),
(8, 6, '2 Tbsps Sweet Pickle Relish'),
(8, 7, '1 Romaine Lettuce Heart'),
(8, 8, '1 Tbsp Weeknight Hero Spice Blend (Garlic Powder, Onion Powder, Smoked Paprika, & Whole Dried Parsley)'),
(8, 9, '1¼ cups Panko Breadcrumbs'),
(8, 10, '¼ cup Creamy Mustard Sauce'),
(9, 1, '10 oz Chopped Chicken Breast'),
(9, 2, '1 head Baby Bok Choy'),
(9, 3, '¾ cup Jasmine Rice'),
(9, 4, '2 cloves Garlic'),
(9, 5, '1 Tbsp Rice Vinegar'),
(9, 6, '1 1-Inch Piece Ginger'),
(9, 7, '1 tsp Sriracha'),
(9, 8, '1 Tbsp Honey'),
(9, 9, '1 Tbsp Sesame Oil'),
(9, 10, '¼ cup Cornstarch'),
(9, 11, '2 Tbsps Hoisin Sauce'),
(10, 1, '½ lb Green Cabbage'),
(10, 2, '1 Tbsp Rice Vinegar'),
(10, 3, '4 Boneless, Center-Cut Pork Chops'),
(10, 4, '2 Carrots'),
(10, 5, '1 bunch Chives'),
(10, 6, '2 Tbsps Tahini'),
(10, 7, '2 Tbsps Soy Sauce'),
(10, 8, '¾ lb Fresh Wonton Noodles'),
(10, 9, '2 tsps Sambal Oelek'),
(10, 10, '1 1-Inch Piece Ginger'),
(10, 11, '¼ cup Hoisin Sauce'),
(11, 1, '4 Carrots'),
(11, 2, '6 oz Radishes'),
(11, 3, '1 Lemon'),
(11, 4, '2 cloves Garlic'),
(11, 5, '1 bunch Parsley'),
(11, 6, '2 Tbsps Butter'),
(11, 7, '2 Tbsps Honey'),
(11, 8, '4 Skin-On Barramundi Fillets'),
(11, 9, '½ cup Plain Greek Yogurt'),
(11, 10, '1⅛ lbs Yukon Gold Potatoes'),
(11, 11, '1 Tbsp Za\'atar Seasoning (Ground Sumac, Sesame Seeds, Salt, Ground Thyme, Whole Dried Oregano, & Crushed Aleppo Pepper)'),
(12, 1, '1 Pie Crust (in Tin)'),
(12, 2, '1 bunch Kale'),
(12, 3, '2 cloves Garlic'),
(12, 4, '1 Shallot'),
(12, 5, '½ cup Heavy Cream'),
(12, 6, '1 Lemon'),
(12, 7, '1 Apple'),
(12, 8, '4 Cage-Free Farm Eggs'),
(12, 9, '1 cup Part-Skim Ricotta Cheese'),
(12, 10, '1 Romaine Lettuce Heart'),
(12, 11, '2 Tbsps Sliced Roasted Almonds'),
(12, 12, '1 Tbsp Cajun Spice Blend (Smoked Paprika, Ground Yellow Mustard, Onion Powder, Garlic Powder, Whole Dried Oregano, Whole Dried Thyme, & Cayenne Pepper)'),
(12, 13, '2 Tbsps Crème Fraîche'),
(13, 1, '2 Skin-On Barramundi Fillets'),
(13, 2, '1 Sweet Potato'),
(13, 3, '1 bunch Kale'),
(13, 4, '1 Avocado'),
(13, 5, '1 Lime'),
(13, 6, '1 Navel Orange'),
(13, 7, '1 clove Garlic'),
(13, 8, '2 Tbsps Roasted Pepitas'),
(13, 9, '1 Tbsp Mexican Spice Blend (Ancho Chile Powder, Smoked Paprika, Garlic Powder, Ground Cumin, & Dried Mexican Oregano)'),
(14, 1, '4 Flour Tortillas'),
(14, 2, '3 oz Radishes'),
(14, 3, '1 Orange'),
(14, 4, '¾ lb Yukon Gold Potatoes'),
(14, 5, '6 oz Cremini Mushrooms'),
(14, 6, '1 Shallot'),
(14, 7, '3 Tbsps Roasted Peanuts'),
(14, 8, '¼ cup Sour Cream'),
(14, 9, '1 oz Sliced Pickled Jalapeño Pepper'),
(14, 10, '1 oz Golden Or Red Sweet Piquante Peppers'),
(14, 11, '1 Tbsp Spanish Spice Blend (Smoked Paprika, Ground Cumin, Ground Coriander, Dried Mexican Oregano, Cayenne Pepper, & Ground Cinnamon)'),
(14, 12, '1 Romaine Lettuce Heart'),
(14, 13, '2 Tbsps Rice Vinegar'),
(15, 1, '1½ lbs Sweet Potatoes'),
(15, 2, '1 lb Broccoli'),
(15, 3, '1 Lemon'),
(15, 4, '2 Tbsps Butter'),
(15, 5, '¼ cup Mayonnaise'),
(15, 6, '4 Boneless, Skinless Chicken Breasts'),
(15, 7, '¼ cup All-Purpose Flour'),
(15, 8, '½ cup Grated Parmesan Cheese'),
(15, 9, '1 Tbsp Weeknight Hero Spice Blend (Garlic Powder, Onion Powder, Smoked Paprika, & Whole Dried Parsley)'),
(16, 1, '10 oz Ground Beef'),
(16, 2, '2 Potato Buns'),
(16, 3, '1 Sweet Potato'),
(16, 4, '2 oz Cheddar Cheese'),
(16, 5, '1 oz Sweet Piquante Peppers'),
(16, 6, '2 Tbsps Mayonnaise'),
(16, 7, '1 tsp Pimento Cheese Spice Blend (Garlic Powder, Ground Yellow Mustard, & Sugar)'),
(17, 1, '6 Flour Tortillas'),
(17, 2, '½ lb Green Cabbage'),
(17, 3, '1 Orange'),
(17, 4, '1 Lime'),
(17, 5, '3 oz Radishes'),
(17, 6, '1 clove Garlic'),
(17, 7, '¾ lb Yukon Gold Potatoes'),
(17, 8, '10 oz Ground Pork Chorizo'),
(17, 9, '2 Tbsps Crème Fraîche'),
(17, 10, '2 Tbsps Grated Cotija Cheese'),
(18, 1, '2 Cage-Free Farm Eggs'),
(18, 2, '½ cup Fregola Sarda Pasta'),
(18, 3, '1 clove Garlic'),
(18, 4, '1 lb Broccoli'),
(18, 5, '1 Red Onion'),
(18, 6, '1 bunch Mint'),
(18, 7, '2 Tbsps Tahini'),
(18, 8, '1 oz Pecorino Romano Cheese'),
(18, 9, '1 Tbsp Za\'atar Seasoning (Ground Sumac, Sesame Seeds, Salt, Ground Thyme, Whole Dried Oregano, & Crushed Aleppo Pepper)'),
(18, 10, '3 Tbsps Roasted Almonds'),
(18, 11, '1 Lemon'),
(19, 1, '⅔ cup Cracked Freekeh'),
(19, 2, '½ cup Sheep\'s Milk Yogurt'),
(19, 3, '2 Carrots'),
(19, 4, '2 cloves Garlic'),
(19, 5, '1 Lemon'),
(19, 6, '1 bunch Mint'),
(19, 7, '2 Dried Medjool Dates'),
(19, 8, '2 Tbsps Pickled Peruvian Peppers'),
(19, 9, '1¾ oz Barrel-Aged Feta Cheese'),
(19, 10, '2 Tbsps Roasted Almonds'),
(19, 11, '¼ tsp Crushed Red Pepper Flakes'),
(19, 12, '¾ lb Brussels Sprouts'),
(20, 1, '1 bunch Kale'),
(20, 2, '2 Cage-Free Farm Eggs'),
(20, 3, '2 cloves Garlic'),
(20, 4, '1 head Cauliflower'),
(20, 5, '1 Lemon'),
(20, 6, '2 Tbsps Butter'),
(20, 7, '1 Shallot'),
(20, 8, '1 Tbsp Capers'),
(20, 9, '3 Tbsps Panko Breadcrumbs'),
(20, 10, '¼ cup Grated Parmesan Cheese'),
(21, 1, '2 Half Chickens'),
(21, 2, '1 lb Sweet Potatoes'),
(21, 3, '4 oz Cranberries'),
(21, 4, '½ lb Brussels Sprouts'),
(21, 5, '2 Tbsps Apple Cider Vinegar'),
(21, 6, '2 Tbsps Sugar'),
(21, 7, '1 1-Inch Piece Ginger'),
(21, 8, '¼ cup Roasted Walnuts'),
(21, 9, '1 Tbsp Weeknight Hero Spice Blend (Garlic Powder, Onion Powder, Smoked Paprika, & Whole Dried Parsley)'),
(22, 1, '1 Pork Tenderloin'),
(22, 2, '½ lb Broccoli'),
(22, 3, '2 cloves Garlic'),
(22, 4, '1 Apple'),
(22, 5, '2 oz Fontina Cheese'),
(22, 6, '¼ cup Milk'),
(22, 7, '3 Tbsps Panko Breadcrumbs'),
(22, 8, '2 Tbsps All-Purpose Flour'),
(22, 9, '1 Tbsp Apple Cider Vinegar'),
(22, 10, '1 Tbsp Southern Spice Blend (Onion Powder, Garlic Powder, Ground Yellow Mustard, Smoked Paprika, & Cayenne Pepper)'),
(23, 1, '½ lb Broccoli'),
(23, 2, '1 Lemon'),
(23, 3, '2 cloves Garlic'),
(23, 4, '1 Tbsp Capers'),
(23, 5, '1 Tbsp Tomato Paste'),
(23, 6, '¼ cup Heavy Cream'),
(23, 7, '1 Tbsp Butter'),
(23, 8, '6 oz Whole Grain Pipe Rigate Pasta'),
(23, 9, '2 oz Roasted Piquillo Peppers'),
(23, 10, '2 Tbsps Grated Parmesan Cheese'),
(23, 11, '2 Tbsps Sliced Roasted Almonds'),
(23, 12, '1½ tsps Calabrian Chile Paste'),
(24, 1, '1 Spaghetti Squash'),
(24, 2, '1 Lime Leaf'),
(24, 3, '½ cup Jasmine Rice'),
(24, 4, '1¾ cups Light Coconut Milk'),
(24, 5, '1 Lime'),
(24, 6, '1 Yellow Onion'),
(24, 7, '1 bunch Mint'),
(24, 8, '2 Tbsps Dried Mung Beans'),
(24, 9, '1½ Tbsps Yellow Curry Paste'),
(24, 10, '1 1-Inch Piece Ginger'),
(24, 11, '1 Tbsp Sugar'),
(24, 12, '½ lb Baby Bok Choy'),
(25, 1, '1 Turkey Breast Roast'),
(25, 2, '⅔ cup Semi-Pearled Farro'),
(25, 3, '1 Apple'),
(25, 4, '1 Lemon'),
(25, 5, '1 Endive'),
(25, 6, '1 bunch Chives'),
(25, 7, '2 Tbsps Butter'),
(25, 8, '1 Shallot'),
(25, 9, '1 Tbsp Honey'),
(25, 10, '1 Tbsp Whole Grain Dijon Mustard'),
(26, 1, '1 bunch Mint'),
(26, 2, '2 Skin-On Salmon Fillets'),
(26, 3, '2 cloves Garlic'),
(26, 4, '6 oz Carrots'),
(26, 5, '1 Lemon'),
(26, 6, '¾ lb Yukon Gold Potatoes'),
(26, 7, '1 Pinch Saffron'),
(26, 8, '1 Tbsp Honey'),
(26, 9, '½ cup Plain Greek Yogurt'),
(26, 10, '½ tsp Crushed Aleppo Pepper'),
(26, 11, '½ tsp Ground Cumin'),
(27, 1, '½ lb Carrots'),
(27, 2, '2 Tbsps Maple Syrup'),
(27, 3, '1 Tbsp Butter'),
(27, 4, '2 Boneless, Skinless Chicken Breasts'),
(27, 5, '¾ lb Yukon Gold Potatoes'),
(27, 6, '2 Tbsps Crème Fraîche'),
(27, 7, '1 Tbsp Sherry Vinegar'),
(28, 1, '2 Strip Steaks'),
(28, 2, '1 head Butter Lettuce'),
(28, 3, '2 cloves Garlic'),
(28, 4, '2 Russet Potatoes'),
(28, 5, '1 bunch Chives'),
(28, 6, '3 Tbsps Creamy Mustard Sauce'),
(28, 7, '2 Tbsps Butter'),
(28, 8, '1 Tbsp Red Wine Vinegar'),
(29, 1, '1¼ lbs Ground Beef'),
(29, 2, '4 Potato Buns'),
(29, 3, '2 cloves Garlic'),
(29, 4, '2 Scallions'),
(29, 5, '2 Sweet Potatoes'),
(29, 6, '½ lb Baby Bok Choy'),
(29, 7, '2 Tbsps Hoisin Sauce'),
(29, 8, '2 Tbsps Sweet White Miso Paste'),
(29, 9, '½ oz Dried Shiitake Mushrooms'),
(29, 10, '¼ cup Mayonnaise'),
(30, 1, '10 oz Peeled & Deveined Shrimp'),
(30, 2, '½ lb Green Cabbage'),
(30, 3, '6 oz Lumaca Rigata Pasta'),
(30, 4, '2 cloves Garlic'),
(30, 5, '1 8-Ounce Can Tomato Sauce'),
(30, 6, '1½ tsps Calabrian Chile Paste'),
(30, 7, '2 Tbsps Crème Fraîche'),
(30, 8, '2 Tbsps Sliced Roasted Almonds'),
(30, 9, '2 Tbsps Verjus Blanc'),
(31, 1, '1 bunch Kale'),
(31, 2, '1 Endive'),
(31, 3, '2 cloves Garlic'),
(31, 4, '2 oz Smoked Gouda Cheese'),
(31, 5, '2 oz Fontina Or Aged Alpine Cheese'),
(31, 6, '1 Red Onion'),
(31, 7, '¾ lb Pizza Dough'),
(31, 8, '4 oz Cremini Mushrooms'),
(31, 9, '1 Apple'),
(31, 10, '1 Tbsp Honey'),
(31, 11, '1 Tbsp Apple Cider Vinegar'),
(32, 1, '2 Boneless, Skinless Chicken Breasts'),
(32, 2, '4 Flour Tortillas'),
(32, 3, '2 Scallions'),
(32, 4, '6 oz Chioggia Beet'),
(32, 5, '1 Jalapeño Pepper'),
(32, 6, '1 Lime'),
(32, 7, '1 Navel Orange'),
(32, 8, '3 Tbsps Roasted Peanuts'),
(32, 9, '2 oz White Cheddar Cheese'),
(32, 10, '¼ cup Mexican Crema'),
(32, 11, '1 Tbsp Mexican Spice Blend (Ancho Chile Powder, Smoked Paprika, Garlic Powder, Ground Cumin, & Dried Mexican Oregano)'),
(33, 1, '1 lb Ground Pork'),
(33, 2, '1 lb Korean Rice Cakes'),
(33, 3, '2 cloves Garlic'),
(33, 4, '2 heads Baby Bok Choy'),
(33, 5, '2 Tbsps Soy Glaze'),
(33, 6, '1½ Tbsps Gochujang'),
(33, 7, '1 1-Inch Piece Ginger'),
(33, 8, '¼ cup Black Bean Sauce'),
(33, 9, '¼ cup Crème Fraîche'),
(33, 10, '1 bunch Chives'),
(34, 1, '¾ cup Jasmine Rice'),
(34, 2, '2 Carrots'),
(34, 3, '2 stalks Celery'),
(34, 4, '1 head Baby Bok Choy'),
(34, 5, '1 Orange'),
(34, 6, '1 Lemon'),
(34, 7, '2 cloves Garlic'),
(34, 8, '3 oz Radishes'),
(34, 9, '1 Tbsp Sesame Oil'),
(34, 10, '2 Tbsps Soy Glaze'),
(34, 11, '2 Cage-Free Farm Eggs'),
(34, 12, '1 1-Inch Piece Ginger'),
(34, 13, '1½ Tbsps Soy Marinade'),
(34, 14, '2 Tbsps Roasted Peanuts'),
(35, 1, '¾ cup Jasmine Rice'),
(35, 2, '10 oz Chopped Chicken Breast'),
(35, 3, '1¾ cups Light Coconut Milk'),
(35, 4, '3 Carrots'),
(35, 5, '1 Lime'),
(35, 6, '1 head Baby Bok Choy'),
(35, 7, '½ cup Dried Shiitake Mushrooms'),
(35, 8, '2 tsps Golden Mountain Sauce'),
(35, 9, '1½ Tbsps Yellow Curry Paste'),
(36, 1, '2 Tilapia Fillets'),
(36, 2, '½ cup Black Beluga Lentils'),
(36, 3, '2 cloves Garlic'),
(36, 4, '1 Lemon'),
(36, 5, '½ lb Broccoli'),
(36, 6, '1 bunch Parsley'),
(36, 7, '2 Tbsps Butter'),
(36, 8, '1 oz Golden Or Red Sweet Piquante Peppers'),
(36, 9, '1 Tbsp Capers'),
(37, 1, '10 oz Ground Chicken'),
(37, 2, '1 head Butter Lettuce'),
(37, 3, '1 Navel Orange'),
(37, 4, '3 oz Radishes'),
(37, 5, '2 Scallions'),
(37, 6, '1 1-Inch Piece Ginger'),
(37, 7, '2 cloves Garlic'),
(37, 8, '2 Tbsps Coconut Aminos'),
(37, 9, '1 Tbsp Rice Vinegar'),
(37, 10, '2 Tbsps Roasted Cashews'),
(37, 11, '1 tsp Togarashi Seasoning (Chile Pepper, Orange Peel, Sesame Seeds, Ginger, & Seaweed)'),
(37, 12, '4 oz Cremini Mushrooms'),
(37, 13, '1 Red Onion'),
(37, 14, '1 Carrot'),
(37, 15, '1 Lime'),
(38, 1, '2 Grassfed Strip Steaks'),
(38, 2, '¾ cup Jasmine Rice'),
(38, 3, '1 1-Inch Piece Ginger'),
(38, 4, '2 cloves Garlic'),
(38, 5, '2 Tbsps Ponzu Sauce'),
(38, 6, '2 Tbsps Soy Sauce'),
(38, 7, '1 tsp Sugar'),
(38, 8, '4 oz Snow Peas'),
(38, 9, '2 Carrots'),
(38, 10, '1 head Baby Bok Choy'),
(38, 11, '2 Scallions'),
(38, 12, '1 Tbsp Butter'),
(39, 1, '¾ cup Jasmine Rice'),
(39, 2, '1 Shallot'),
(39, 3, '2 heads Baby Bok Choy'),
(39, 4, '1 Lime'),
(39, 5, '6 oz Radishes'),
(39, 6, '2 Tbsps Ponzu Sauce'),
(39, 7, '1 Tbsp Soy Marinade'),
(39, 8, '1 Tbsp Sugar'),
(39, 9, '2 Grassfed Strip Steaks'),
(39, 10, '4 oz Cremini Mushrooms'),
(39, 11, '1 1-Inch Piece Ginger'),
(39, 12, '2 Tbsps Sweet Chili Sauce'),
(40, 1, '2 Boneless, Skinless Chicken Breasts'),
(40, 2, '2 Carrots'),
(40, 3, '1 Red Onion'),
(40, 4, '2 cloves Garlic'),
(40, 5, '½ cup French Green Lentils'),
(40, 6, '1 bunch Collard Greens'),
(40, 7, '2 Tbsps Tomato Paste'),
(40, 8, '¼ tsp Crushed Red Pepper Flakes'),
(40, 9, '1 Tbsp Capers'),
(40, 10, '1 Tbsp Apple Cider Vinegar'),
(40, 11, '2 Tbsps Crumbled Goat Cheese'),
(40, 12, '1 Tbsp Tuscan Spice Blend (Ground Fennel Seeds, Whole Fennel Seeds, Ground Rosemary, & Ground Sage)');

--
-- Dumping data for table `tools`
--

INSERT INTO `tools` (`id`, `tool_name`, `tool_brand`, `tool_description`) VALUES
(1, 'Garlic Press', 'Harold Import Company', 'Slicing garlic has never been simpler. This two-sided essential is designed to do two jobs in one: crush garlic and slice it. Made by Harold Import Company, a family-owned American business with over 50 years of experience, this easy-to-use press owes its incredible durability to its heavyweight, stainless steel construction. To use it, simply place the clove in the hopper and press downward for freshly pressed garlic, or flip it over to get uniform slices of garlic. And to ensure minimal mess, it includes a handy cleaning tool for removing leftover pressed garlic after use.'),
(2, 'Slotted Spatula', NULL, 'Master your flipping skills with this commercial-grade slotted turner. This spatula is designed for delicate fish, but we use this versatile tool for anything that requires a deft hand for tricky flipping, such as over-easy eggs, paper-thin crepes or even a burger. With its low-angled beveled edge and flexible blade, this turner slips easily between the pan and your dinner, ensuring even the most delicate meal remains in picture-perfect condition.'),
(3, 'Large Maple Cutting Board', 'John Boos & Co. for Blue Apron', 'Built to last, this chopping board is prized by professional chefs and so gorgeous we never want to take it off the counter. Crafted with hardy American maple, this exclusive collaboration between Blue Apron and John Boos & Co. is equal parts beautiful and handy. Its durable surface won\'t warp and is resistant to scoring; magically, it also helps keep your blades sharper than other materials. You\'ll find these boards in our test kitchen—as well as professional kitchens around the world.'),
(4, 'Olive Wood Spoon', 'Eddington', 'Stir some old-world charm into your next meal with this sturdy spoon made from Italian-grown olive wood. For home cooks and professional chefs alike, this multi-purpose 14" blunt-end spoon is a must-have item. Stain and odor resistant, this spoon will not scratch porcelain, ceramic, glass, or enamel surfaces, and won\'t heat up while you stir. Each unique olive wood spoon brings a sense of quality and professionalism to even the simplest tasks, like stirring sauce or deglazing a pan.'),
(5, 'Stainless Steel Strainer', NULL, 'A stainless steel strainer is a handy tool for quinoa. It\'s great for draining grains and pastas (not to mention small fruits and vegetables after washing) and straining stocks and gravy. Lightweight and sturdy, it\'s constructed with a double-fine mesh.'),
(6, 'Box Grater', NULL, 'This sturdy tool offers four grater sizes, a comfortable grip, and a design that\'s easy to clean. Whether carrots or cheddar, rutabaga or gouda, this box grater shreds everything from root veggies to cheese with ease. Simple and sturdy, the stainless steel grater features four precision-cut surfaces that yield coarse, medium, fine, and super fine textures; there\'s also a slicing edge. Its easy-grip handle allows for efficient, comfortable work and its straight-edged base won\'t collect stray bits, making for quicker clean up.'),
(7, 'Quarter-Sheet Pan', 'Nordic Ware', 'Whether you\'re flying solo or making dinner for two, this delightfully durable pan is about to become your next kitchen essential. This smaller version of the classic sheet pan is ideal for toasting up bread or whipping up a small batch of roasted vegetables for a single meal. Easy to store, its raised lip catches and contains juices while minimizing mess inside the oven. Rustproof and even-heating, this pan has a galvanized steel reinforcement around the rim, which adds to its strength.'),
(8, '11" PFOA-Free CTX Nonstick Pan', 'Scanpan', 'A true stovetop trifecta: nonstick, heavy duty, and environmentally sound. When meal prep requires a delicate touch—think eggs over easy or a seared salmon fillet—our culinary team grabs this even-heating, toxin-free pan. The patented ceramic titanium coating stands up to utensils (yes, even metal!), and best of all, it\'s easy to clean.'),
(9, 'Salad Spinner, Family Plan', 'Zyliss', 'Cut down on prep time with this Swiss-designed salad spinner. Why we love this: Because every Blue Apron recipe starts with "wash and dry the fresh produce". Shortcut this step with the award-winning Zyliss salad spinner. With just one pump of the lever, your greens will spin dry and be ready for step two.'),
(10, '12.5" PFOA-Free CTX Nonstick Pan', 'Scanpan', 'This customer favorite is a true stovetop trifecta: nonstick, heavy duty, and environmentally sound. When meal prep requires a delicate touch—think eggs over easy or a seared salmon fillet—our culinary team grabs this even-heating, toxicant-free pan. The patented ceramic titanium coating stands up to utensils (yes, even metal!), and best of all, it\'s easy to clean.');

--
-- Dumping data for table `recipe_tools`
--

INSERT INTO `recipe_tools` (`recipe_id`, `tool_id`) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 5),
(7, 6),
(8, 2),
(9, 4),
(10, 5),
(11, 3),
(12, 3),
(13, 3),
(14, 7),
(15, 3),
(16, 2),
(17, 7),
(18, 3),
(19, 5),
(20, 8),
(21, 7),
(22, 3),
(23, 3),
(24, 8),
(25, 5),
(26, 3),
(27, 3),
(28, 9),
(29, 10),
(30, 5),
(31, 4),
(32, 5),
(33, 3),
(34, 3),
(35, 4),
(36, 5),
(37, 3),
(38, 3),
(39, 3),
(40, 5);

--
-- Dumping data for table `tool_images`
--

INSERT INTO `tool_images` (`recipe_id`, `tool_id`, `position`, `image`) VALUES
(1, 1, 1, 'images/ancho-orange-chicken/tool-1.jpg'),
(1, 1, 2, 'images/ancho-orange-chicken/tool-2.jpg'),
(2, 2, 1, 'images/beef-medallions-mushroom-sauce/tool-1.jpg'),
(3, 3, 1, 'images/broccoli-basil-pesto-sandwiches/tool-1.jpg'),
(3, 3, 2, 'images/broccoli-basil-pesto-sandwiches/tool-2.jpg'),
(4, 4, 1, 'images/broccoli-mozzarella-calzones/tool-1.jpg'),
(4, 4, 2, 'images/broccoli-mozzarella-calzones/tool-2.jpg'),
(4, 4, 3, 'images/broccoli-mozzarella-calzones/tool-3.jpg'),
(5, 5, 1, 'images/bucatini-alfredo/tool-1.jpg'),
(5, 5, 2, 'images/bucatini-alfredo/tool-2.jpg'),
(6, 5, 1, 'images/bucatini-tomato-sauce/tool-1.jpg'),
(6, 5, 2, 'images/bucatini-tomato-sauce/tool-2.jpg'),
(7, 6, 1, 'images/cheesy-enchiladas-rojas/tool-1.jpg'),
(7, 6, 2, 'images/cheesy-enchiladas-rojas/tool-2.jpg'),
(8, 2, 1, 'images/crispy-fish-sandwiches/tool-1.jpg'),
(9, 4, 1, 'images/general-tsos-chicken/tool-1.jpg'),
(9, 4, 2, 'images/general-tsos-chicken/tool-2.jpg'),
(9, 4, 3, 'images/general-tsos-chicken/tool-3.jpg'),
(10, 5, 1, 'images/hoisin-glazed-pork-chops/tool-1.jpg'),
(10, 5, 2, 'images/hoisin-glazed-pork-chops/tool-2.jpg'),
(11, 3, 1, 'images/honey-butter-barramundi/tool-1.jpg'),
(11, 3, 2, 'images/honey-butter-barramundi/tool-2.jpg'),
(12, 3, 1, 'images/kale-ricotta-quiche/tool-1.jpg'),
(12, 3, 2, 'images/kale-ricotta-quiche/tool-2.jpg'),
(13, 3, 1, 'images/mexican-spiced-barramundi/tool-1.jpg'),
(13, 3, 2, 'images/mexican-spiced-barramundi/tool-2.jpg'),
(14, 7, 1, 'images/mushroom-potato-tacos/tool-1.jpg'),
(14, 7, 2, 'images/mushroom-potato-tacos/tool-2.jpg'),
(15, 3, 1, 'images/parmesan-crusted-chicken/tool-1.jpg'),
(15, 3, 2, 'images/parmesan-crusted-chicken/tool-2.jpg'),
(16, 2, 1, 'images/pimento-cheeseburgers/tool-1.jpg'),
(17, 7, 1, 'images/pork-chorizo-tacos/tool-1.jpg'),
(17, 7, 2, 'images/pork-chorizo-tacos/tool-2.jpg'),
(18, 3, 1, 'images/roasted-broccoli-fregola-sarda-salad/tool-1.jpg'),
(18, 3, 2, 'images/roasted-broccoli-fregola-sarda-salad/tool-2.jpg'),
(19, 5, 1, 'images/roasted-brussels-sprout-freekeh-salad/tool-1.jpg'),
(19, 5, 2, 'images/roasted-brussels-sprout-freekeh-salad/tool-2.jpg'),
(20, 8, 1, 'images/roasted-cauliflower-salad/tool-1.jpg'),
(20, 8, 2, 'images/roasted-cauliflower-salad/tool-2.jpg'),
(21, 7, 1, 'images/roasted-chicken-fall-vegetables/tool-1.jpg'),
(21, 7, 2, 'images/roasted-chicken-fall-vegetables/tool-2.jpg'),
(22, 3, 1, 'images/roasted-pork-broccoli/tool-1.jpg'),
(22, 3, 2, 'images/roasted-pork-broccoli/tool-2.jpg'),
(23, 3, 1, 'images/roasted-red-pepper-pasta/tool-1.jpg'),
(23, 3, 2, 'images/roasted-red-pepper-pasta/tool-2.jpg'),
(24, 8, 1, 'images/roasted-squash-curry/tool-1.jpg'),
(24, 8, 2, 'images/roasted-squash-curry/tool-2.jpg'),
(25, 5, 1, 'images/roasted-turkey-breast-farro-endive-salad/tool-1.jpg'),
(25, 5, 2, 'images/roasted-turkey-breast-farro-endive-salad/tool-2.jpg'),
(26, 3, 1, 'images/salmon-honey-glazed-carrots/tool-1.jpg'),
(26, 3, 2, 'images/salmon-honey-glazed-carrots/tool-2.jpg'),
(27, 3, 1, 'images/seared-chicken-mashed-potatoes/tool-1.jpg'),
(27, 3, 2, 'images/seared-chicken-mashed-potatoes/tool-2.jpg'),
(28, 9, 1, 'images/seared-steaks-garlic-butter/tool-1.jpg'),
(28, 9, 2, 'images/seared-steaks-garlic-butter/tool-2.jpg'),
(29, 10, 1, 'images/shiitake-hoisin-beef-burgers/tool-1.jpg'),
(29, 10, 2, 'images/shiitake-hoisin-beef-burgers/tool-2.jpg'),
(29, 10, 3, 'images/shiitake-hoisin-beef-burgers/tool-3.jpg'),
(30, 5, 1, 'images/shrimp-fra-diavolo/tool-1.jpg'),
(30, 5, 2, 'images/shrimp-fra-diavolo/tool-2.jpg'),
(31, 4, 1, 'images/smoked-gouda-mushroom-flatbread/tool-1.jpg'),
(31, 4, 2, 'images/smoked-gouda-mushroom-flatbread/tool-2.jpg'),
(31, 4, 3, 'images/smoked-gouda-mushroom-flatbread/tool-3.jpg'),
(32, 5, 1, 'images/spicy-chicken-quesadillas/tool-1.jpg'),
(32, 5, 2, 'images/spicy-chicken-quesadillas/tool-2.jpg'),
(33, 3, 1, 'images/spicy-pork-korean-rice-cakes/tool-1.jpg'),
(33, 3, 2, 'images/spicy-pork-korean-rice-cakes/tool-2.jpg'),
(34, 3, 1, 'images/sweet-sour-vegetable-stir-fry/tool-1.jpg'),
(34, 3, 2, 'images/sweet-sour-vegetable-stir-fry/tool-2.jpg'),
(35, 4, 1, 'images/thai-curry-chicken/tool-1.jpg'),
(35, 4, 2, 'images/thai-curry-chicken/tool-2.jpg'),
(35, 4, 3, 'images/thai-curry-chicken/tool-3.jpg'),
(36, 5, 1, 'images/tilapia-black-lentil-salad/tool-1.jpg'),
(36, 5, 2, 'images/tilapia-black-lentil-salad/tool-2.jpg'),
(37, 3, 1, 'images/togarashi-chicken-lettuce-cups/tool-1.jpg'),
(37, 3, 2, 'images/togarashi-chicken-lettuce-cups/tool-2.jpg'),
(38, 3, 1, 'images/top-chef-ginger-marinated-grassfed-steaks/tool-1.jpg'),
(38, 3, 2, 'images/top-chef-ginger-marinated-grassfed-steaks/tool-2.jpg'),
(39, 3, 1, 'images/top-chef-seared-grassfed-steaks/tool-1.jpg'),
(39, 3, 2, 'images/top-chef-seared-grassfed-steaks/tool-2.jpg'),
(40, 5, 1, 'images/tuscan-chicken-green-lentil-stew/tool-1.jpg'),
(40, 5, 2, 'images/tuscan-chicken-green-lentil-stew/tool-2.jpg');

--
-- Dumping data for table `tips`
--

INSERT INTO `tips` (`recipe_id`, `tip_type`, `tip_title`, `tip_text`, `tip_image`) VALUES
(3, 'how_to', 'Peel Garlic', 'If you\'re cooking with us, you\'re using garlic in virtually every recipe. Don\'t waste any more time trying to peel it! Check out the video for a quick tip.', 'images/broccoli-basil-pesto-sandwiches/tip.jpg'),
(4, 'how_to', 'Roll Pizza Dough', 'Rolling out pizza dough may seem tricky—but with a few simple steps (and enough time for the dough to rest), you can achieve perfect results at home. Watch this short video to see how our chef does it.', 'images/broccoli-mozzarella-calzones/tip.jpg'),
(6, 'how_to', 'Make Sure Your Pasta is Al Dente', 'Nothing beats perfectly cooked, al dente pasta. But how do you know if it\'s done? There are numerous ways to test the doneness of your noodles when they\'re cooking. Some folk wisdom says to throw a piece of pasta against the wall; if it sticks, it\'s done. As much fun as we had experimenting with this method, we found the best way to test the pasta was, shockingly, by tasting it. In Italian, "al dente" means "to the tooth," meaning that it\'s still slightly firm to the bite. As your pasta cooks, periodically (and carefully) taste a piece of it. If it\'s still too firm, let it cook a little longer. In some of our recipes, we specify to remove the pasta from the pot when it\'s "just shy of al dente." This is because, later, the pasta will be cooked in a sauce. Removing the pasta from the water just before it\'s al dente will ensure that the final product isn\'t overcooked.', 'images/bucatini-tomato-sauce/tip.jpg'),
(7, 'how_to', 'Separate Leafy Greens from the Stems', 'Check out this simple trick for separating the stems and leaves of one of our favorite ingredients: kale. You won\'t even need a knife!', 'images/cheesy-enchiladas-rojas/tip.jpg'),
(9, 'how_to', 'Peel Garlic', 'If you\'re cooking with us, you\'re using garlic in virtually every recipe. Don\'t waste any more time trying to peel it! Check out the video for a quick tip.', 'images/general-tsos-chicken/tip.jpg'),
(10, 'how_to', 'Peel a Carrot', 'Make quick work of this deliciously sweet root vegetable. Check out the video to see how it\'s done.', 'images/hoisin-glazed-pork-chops/tip.png'),
(14, 'how_to', 'Hold a Chef\'s Knife', 'At the core of many knife skills in holding the knife properly. This simple grip gives you all the power and freedom you\'ll need to prep whatever\'s on your cutting board. So get a grip and watch this short video to see how it\'s done!', 'images/mushroom-potato-tacos/tip.png'),
(16, 'ingredient_spotlight', 'Sweet Potato', 'Despite its name, the sweet potato is not related to the group of vegetables we know as "potatoes"—rather, the sweet potato is actually a member of the morning glory family. Columbus brought the tropical root crop back to Europe from the Americas. It was eagerly adopted by Europeans and given the title of "potato" (from the indigenous Taino name, "batata"). Years later, in 1537, when the white potato first arrived in Europe, locals began referring to both vegetables as "potatoes," creating a confusion that persists today. Sweet potatoes are enjoyed in both regular and "baby" varieties—smaller versions of the vegetable that are renowned for their sweet flavor and tender flesh.', 'images/pimento-cheeseburgers/tip.jpg'),
(18, 'how_to', 'Quarter and Deseed a Lemon', 'Lemons are indispensable to cooking. Their tart juice brightens other flavors and can tie a dish together. We\'ve come up with an easy way to get the juice out of the lemon (without having to deal with the pesky seeds). Watch this short video to see how it\'s done.', 'images/roasted-broccoli-fregola-sarda-salad/tip.png'),
(19, 'how_to', 'Get Perfect Citrus Zest', 'Zest is one of the best ways to brighten up a dish. It translates the essential oils of the citrus into flavor for all kinds of meals. See how it\'s done here!', 'images/roasted-brussels-sprout-freekeh-salad/tip.jpg'),
(20, 'how_to', 'Prep Cauliflower Florets', 'Cauliflower is one of our favorite cool-weather vegetables. In certain recipes, we specify to cut the head into small florets. Check out this short video to learn the simple technique that will make prepping cauliflower a snap!', 'images/roasted-cauliflower-salad/tip.jpg'),
(21, 'how_to', 'Peel & Mince Ginger', 'Ginger is a common, aromatic ingredient popular in cuisines throughout the world. Because of its knobby shape, prepping ginger can seem tricky. But simply follow the instructions in this video and you\'ll be prepping like a pro.', 'images/roasted-chicken-fall-vegetables/tip.jpg'),
(24, 'how_to', 'Peel & Mince Ginger', 'Ginger is a common, aromatic ingredient popular in cuisines throughout the world. Because of its knobby shape, prepping ginger can seem tricky. But simply follow the instructions in this video and you\'ll be prepping like a pro.', 'images/roasted-squash-curry/tip.jpg'),
(25, 'how_to', 'Cook Your Grains "Pasta" Style', 'In some of our recipes, we have you measure out water to cook your grains in. In others, we only specify to heat a pot of boiling water and add the grains to it. For the grain in this recipe, an exact ratio of water to grain isn\'t necessary. You just need enough boiling water to give the grain some room and let it dance: a few quarts will do. We chose this method because it\'s more streamlined and easier for hearty grains (like farro, spelt and wild rice). Just think: cook it like pasta!', 'images/roasted-turkey-breast-farro-endive-salad/tip.jpg'),
(26, 'how_to', 'Get Perfect Citrus Zest', 'Zest is one of the best ways to brighten up a dish. It translates the essential oils of the citrus into flavor for all kinds of meals. See how it\'s done here!', 'images/salmon-honey-glazed-carrots/tip.jpg'),
(28, 'how_to', 'Slice Steak', 'Properly sliced steak isn\'t just beautiful to look at. It also ensures that the meat stays tender. You\'ve probably heard the expression "slice the steak against the grain." But what does that mean? Check out this short video to find out!', 'images/seared-steaks-garlic-butter/tip.jpg'),
(29, 'how_to', 'Chop Scallions', 'Scallions, or green onions, are one of our favorite aromatic vegetables. There are two parts of the vegetable: the white bottom and the green top. They\'re used a little differently in cooking—the white bottoms are similar in use to regular onions and are usually cooked; the green tops are often used raw as a garnish. In our recipes, we specify to separate them. Check out this video to see how we do it.', 'images/shiitake-hoisin-beef-burgers/tip.jpg'),
(30, 'how_to', 'Make Sure Your Pasta is Al Dente', 'Nothing beats perfectly cooked, al dente pasta. But how do you know if it\'s done? There are numerous ways to test the doneness of your noodles when they\'re cooking. Some folk wisdom says to throw a piece of pasta against the wall; if it sticks, it\'s done. As much fun as we had experimenting with this method, we found the best way to test the pasta was, shockingly, by tasting it. In Italian, "al dente" means "to the tooth," meaning that it\'s still slightly firm to the bite. As your pasta cooks, periodically (and carefully) taste a piece of it. If it\'s still too firm, let it cook a little longer. In some of our recipes, we specify to remove the pasta from the pot when it\'s "just shy of al dente." This is because, later, the pasta will be cooked in a sauce. Removing the pasta from the water just before it\'s al dente will ensure that the final product isn\'t overcooked.', 'images/shrimp-fra-diavolo/tip.jpg'),
(31, 'how_to', 'Roll Pizza Dough', 'Rolling out pizza dough may seem tricky—but with a few simple steps (and enough time for the dough to rest), you can achieve perfect results at home. Watch this short video to see how our chef does it.', 'images/smoked-gouda-mushroom-flatbread/tip.jpg'),
(32, 'how_to', 'Chop Scallions', 'Scallions, or green onions, are one of our favorite aromatic vegetables. There are two parts of the vegetable: the white bottom and the green top. They\'re used a little differently in cooking—the white bottoms are similar in use to regular onions and are usually cooked; the green tops are often used raw as a garnish. In our recipes, we specify to separate them. Check out this video to see how we do it.', 'images/spicy-chicken-quesadillas/tip.jpg'),
(33, 'how_to', 'Peel Garlic', 'If you\'re cooking with us, you\'re using garlic in virtually every recipe. Don\'t waste any more time trying to peel it! Check out the video for a quick tip.', 'images/spicy-pork-korean-rice-cakes/tip.jpg'),
(35, 'how_to', 'Peel a Carrot', 'Make quick work of this deliciously sweet root vegetable. Check out the video to see how it\'s done.', 'images/thai-curry-chicken/tip.png'),
(36, 'how_to', 'Peel Garlic', 'If you\'re cooking with us, you\'re using garlic in virtually every recipe. Don\'t waste any more time trying to peel it! Check out the video for a quick tip.', 'images/tilapia-black-lentil-salad/tip.jpg'),
(40, 'how_to', 'Separate Leafy Greens from the Stems', 'Check out this simple trick for separating the stems and leaves of one of our favorite ingredients: kale. You won\'t even need a knife!', 'images/tuscan-chicken-green-lentil-stew/tip.jpg');

--
-- Dumping data for table `steps`
--

INSERT INTO `steps` (`recipe_id`, `step_number`, `step_title`, `step_instructions`, `step_image`, `step_image_retina`) VALUES
(1, 1, 'Cook the rice', 'Place an oven rack in the center of the oven, then preheat to 450°F. In a medium pot, combine the rice, a big pinch of salt, and 1 1/2 cups of water. Heat to boiling on high. Once boiling, cover and reduce the heat to low. Cook 12 to 14 minutes, or until the water has been absorbed and the rice is tender. Turn off the heat and fluff with a fork. Cover to keep warm.', 'images/ancho-orange-chicken/step-1.jpg', 'images/ancho-orange-chicken/step-1@2x.jpg'),
(1, 2, 'Prepare the ingredients & make the glaze', 'While the rice cooks, wash and dry the fresh produce. Peel the carrots; quarter lengthwise, then halve crosswise. Peel and roughly chop the garlic. Remove and discard the stems of the kale; finely chop the leaves. Using a peeler, remove the lime rind, avoiding the white pith; mince to get 2 teaspoons of zest (or use a zester). Halve the lime crosswise. Halve the orange; squeeze the juice into a bowl, straining out any seeds. Whisk in the chile paste and 2 tablespoons of water until smooth.', 'images/ancho-orange-chicken/step-2.jpg', 'images/ancho-orange-chicken/step-2@2x.jpg'),
(1, 3, 'Roast the carrots', 'Place the sliced carrots on a sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer. Roast 15 to 17 minutes, or until tender when pierced with a fork. Remove from the oven.', 'images/ancho-orange-chicken/step-3.jpg', 'images/ancho-orange-chicken/step-3@2x.jpg'),
(1, 4, 'Cook the kale & finish the rice', 'While the carrots roast, in a large pan (nonstick, if you have one), heat 2 teaspoons of olive oil on medium-high until hot. Add the chopped garlic and cook, stirring constantly, 30 seconds to 1 minute, or until fragrant. Add the chopped kale; season with salt and pepper. Cook, stirring occasionally, 3 to 4 minutes, or until slightly wilted. Add 1/3 cup of water; season with salt and pepper. Cook, stirring occasionally, 3 to 4 minutes, or until the kale has wilted and the water has cooked off. Transfer to the pot of cooked rice. Stir to combine; season with salt and pepper to taste. Cover to keep warm. Wipe out the pan.', 'images/ancho-orange-chicken/step-4.jpg', 'images/ancho-orange-chicken/step-4@2x.jpg'),
(1, 5, 'Cook & glaze the chicken', 'While the carrots continue to roast, pat the chicken dry with paper towels; season with salt and pepper on both sides. In the same pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the seasoned chicken and cook 4 to 6 minutes on the first side, or until browned. Flip and cook 2 to 3 minutes, or until lightly browned. Add the glaze and cook, frequently spooning the glaze over the chicken, 2 to 3 minutes, or until the chicken is coated and cooked through. Turn off the heat; stir the butter and the juice of 1 lime half into the glaze until the butter has melted. Season with salt and pepper to taste.', 'images/ancho-orange-chicken/step-5.jpg', 'images/ancho-orange-chicken/step-5@2x.jpg'),
(1, 6, 'Finish the rice & serve your dish', 'To the pot of cooked rice and kale, add the lime zest, crème fraîche, raisins, and the juice of the remaining lime half. Stir to combine; season with salt and pepper to taste. Serve the glazed chicken with the finished rice and roasted carrots. Top the chicken with the remaining glaze from the pan. Enjoy!', 'images/ancho-orange-chicken/step-6.jpg', 'images/ancho-orange-chicken/step-6@2x.jpg'),
(2, 1, 'Prepare the ingredients', 'Heat a medium pot of salted water to boiling on high. Wash and dry the fresh produce. Large dice the potatoes. Peel the garlic. Using the flat side of your knife, smash 1 clove to flatten. Roughly chop the remaining clove. Peel and thinly slice the shallot. Remove and discard the stems of the kale; roughly chop the leaves. Thinly slice the mushrooms.', 'images/beef-medallions-mushroom-sauce/step-1.jpg', 'images/beef-medallions-mushroom-sauce/step-1@2x.jpg'),
(2, 2, 'Cook & mash the potatoes', 'Add the diced potatoes and smashed garlic to the pot of boiling water and cook 13 to 15 minutes, or until tender when pierced with a fork. Turn off the heat. Drain thoroughly and return to the pot. Add half the butter and a drizzle of olive oil. Using a fork, mash to your desired consistency. Season with salt and pepper to taste. Cover to keep warm.', 'images/beef-medallions-mushroom-sauce/step-2.jpg', 'images/beef-medallions-mushroom-sauce/step-2@2x.jpg'),
(2, 3, 'Cook the kale', 'While the potatoes cook, in a large pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the sliced shallot; season with salt and pepper. Cook, stirring occasionally, 1 to 2 minutes, or until softened. Add the chopped kale and 1/4 cup of water; season with salt and pepper. Cook, stirring frequently, 3 to 4 minutes, or until the kale has wilted and the water has cooked off. Transfer to a bowl and season with salt and pepper to taste. Cover with aluminum foil to keep warm. Rinse and wipe out the pan.', 'images/beef-medallions-mushroom-sauce/step-3.jpg', 'images/beef-medallions-mushroom-sauce/step-3@2x.jpg'),
(2, 4, 'Cook the beef', 'While the potatoes continue to cook, pat the beef dry with paper towels. Season with salt and pepper on both sides. In the same pan, heat 1 tablespoon of olive oil on medium-high until hot. Add the seasoned beef and cook 2 to 3 minutes per side for medium-rare, or until browned and cooked to your desired degree of doneness. Leaving any browned bits (or fond) in the pan, transfer to a plate and let rest for at least 5 minutes.', 'images/beef-medallions-mushroom-sauce/step-4.jpg', 'images/beef-medallions-mushroom-sauce/step-4@2x.jpg'),
(2, 5, 'Make the mushroom sauce', 'While the beef rests, add a drizzle of olive oil to the pan of reserved fond and heat on medium-high until hot. Add the sliced mushrooms in an even layer. Cook, without stirring, 2 to 3 minutes, or until browned. Add the chopped garlic; season with salt and pepper. Cook, stirring frequently, 1 to 2 minutes, or until softened and fragrant. Add the mustard, verjus, and 2 tablespoons of water (be careful, as the liquid may splatter); season with salt and pepper. Cook, stirring frequently and scraping up any fond, 30 seconds to 1 minute, or until thoroughly combined. Turn off the heat and stir in the remaining butter until melted. (If the sauce seems too thick, gradually add up to 2 tablespoons of water to achieve your desired consistency.) Season with salt and pepper to taste.', 'images/beef-medallions-mushroom-sauce/step-5.jpg', 'images/beef-medallions-mushroom-sauce/step-5@2x.jpg'),
(2, 6, 'Serve your dish', 'Serve the rested beef with the mashed potatoes and cooked kale. Top the beef and potatoes with the mushroom sauce. Enjoy!', 'images/beef-medallions-mushroom-sauce/step-6.jpg', 'images/beef-medallions-mushroom-sauce/step-6@2x.jpg'),
(3, 1, 'Prepare the ingredients & season the tomato sauce', 'Place an oven rack in the center of the oven, then preheat to 475°F. Wash and dry the fresh produce. Cut off and discard the bottom 1/2 inch of the broccoli stem; cut the broccoli into small pieces, keeping the florets intact. Peel and roughly chop the garlic. Halve the focaccia. Grate the asiago cheese on the large side of a box grater. Tear the mozzarella cheese into small pieces. In a bowl, combine the tomato sauce and Italian seasoning; season with salt and pepper to taste.', 'images/broccoli-basil-pesto-sandwiches/step-1.jpg', 'images/broccoli-basil-pesto-sandwiches/step-1@2x.jpg'),
(3, 2, 'Cook the broccoli', 'In a large pan (nonstick, if you have one), heat 2 teaspoons of olive oil on medium-high until hot. Add the broccoli pieces; season with salt and pepper. Cook, stirring occasionally, 3 to 4 minutes, or until slightly softened. Add the chopped garlic; cook, stirring frequently, 1 to 2 minutes, or until slightly softened and fragrant. Add 1/2 cup of water; season with salt and pepper. Cook, stirring occasionally, 4 to 5 minutes, or until the broccoli has softened and the water has cooked off. Turn off the heat.', 'images/broccoli-basil-pesto-sandwiches/step-2.jpg', 'images/broccoli-basil-pesto-sandwiches/step-2@2x.jpg'),
(3, 3, 'Top & bake the focaccia', 'Line a sheet pan with foil. Place the halved focaccia on the foil, cut side up; drizzle with olive oil. Top with the seasoned tomato sauce. Top the focaccia bottom with the grated asiago cheese, half the mozzarella cheese, and the cooked broccoli. Evenly top the broccoli with the remaining mozzarella cheese and pesto (stirring before adding). Season both focaccia halves with salt and pepper. Bake, rotating the sheet pan halfway through, 11 to 13 minutes, or until lightly browned and the cheese has melted. Remove from the oven; let stand for at least 2 minutes. Transfer to a cutting board.', 'images/broccoli-basil-pesto-sandwiches/step-3.jpg', 'images/broccoli-basil-pesto-sandwiches/step-3@2x.jpg'),
(3, 4, 'Prepare the remaining ingredients', 'While the focaccia bakes, cut off and discard the root end of the lettuce; roughly chop the leaves. Place in a large bowl. Roughly chop the peppers. Halve 1 clementine crosswise; squeeze the juice into a bowl, straining out any seeds. Peel the remaining clementine; separate into segments. To make the dressing, add the crème fraîche, mustard, and 1 tablespoon of water to the bowl of clementine juice. Slowly whisk in a drizzle of olive oil until combined; season with salt and pepper to taste.', 'images/broccoli-basil-pesto-sandwiches/step-4.jpg', 'images/broccoli-basil-pesto-sandwiches/step-4@2x.jpg'),
(3, 5, 'Make the salad', 'Just before serving, add the clementine segments, chopped peppers, and dressing to the bowl of chopped lettuce. Toss to thoroughly coat. Season with salt and pepper to taste.', 'images/broccoli-basil-pesto-sandwiches/step-5.jpg', 'images/broccoli-basil-pesto-sandwiches/step-5@2x.jpg'),
(3, 6, 'Assemble the sandwich & serve your dish', 'Evenly top the baked focaccia bottom with the parmesan cheese. Complete with the focaccia top. Using a serrated knife, cut the finished sandwich into 4 equal-sized pieces. Serve with the salad on the side. Enjoy!', 'images/broccoli-basil-pesto-sandwiches/step-6.jpg', 'images/broccoli-basil-pesto-sandwiches/step-6@2x.jpg'),
(4, 1, 'Prepare the ingredients', 'Remove the dough from the refrigerator to bring to room temperature. Place an oven rack in the center of the oven, then preheat to 475°F. Wash and dry the fresh produce. Cut off and discard the bottom 1/2 inch of the broccoli stem, then roughly chop the broccoli. Peel and roughly chop the garlic. Tear the mozzarella cheese into small pieces. Quarter and deseed the lemon.', 'images/broccoli-mozzarella-calzones/step-1.jpg', 'images/broccoli-mozzarella-calzones/step-1@2x.jpg'),
(4, 2, 'Cook the broccoli & make the filling', 'In a large pan (nonstick, if you have one), heat 2 teaspoons of olive oil on medium-high until hot. Add the chopped broccoli; season with salt and pepper. Cook, stirring occasionally, 4 to 6 minutes, or until lightly browned. Add 2/3 of the chopped garlic. Cook, stirring constantly, 30 seconds to 1 minute, or until fragrant. Add 1/4 cup of water; season with salt and pepper. Cook, stirring occasionally, 2 to 3 minutes, or until the broccoli has softened and the water has cooked off. Transfer to a large bowl. Add the mozzarella cheese, ricotta cheese, half the Italian seasoning, and the juice of 1 lemon wedge; stir to combine. Season with salt and pepper. Wipe out the pan.', 'images/broccoli-mozzarella-calzones/step-2.jpg', 'images/broccoli-mozzarella-calzones/step-2@2x.jpg'),
(4, 3, 'Assemble & bake the calzones', 'Lightly oil a sheet pan. Divide the dough into 2 equal-sized portions; using your hands and a rolling pin (or wine bottle), gently stretch and roll the portions into ¼-inch-thick rounds. (If the dough is resistant, let rest for 5 minutes.) Divide the filling between the centers of the rounds; fold each round in half over the filling. Using a fork, crimp the edges of the dough to seal. Transfer to the sheet pan. Using a fork, poke a few holes across the tops of the calzones to vent. Lightly drizzle the calzones with olive oil. Bake 16 to 18 minutes, or until golden brown. Transfer to a cutting board and let stand for at least 2 minutes.', 'images/broccoli-mozzarella-calzones/step-3.jpg', 'images/broccoli-mozzarella-calzones/step-3@2x.jpg'),
(4, 4, 'Prepare the remaining ingredients', 'While the calzones bake, using the flat side of your knife, smash the olives; remove and discard the pits, then roughly chop. Cut off and discard the root end of the lettuce; roughly chop the leaves. To make the dressing, in a large bowl, combine the mayonnaise, half the parmesan cheese, the juice of the remaining lemon wedges, and a drizzle of olive oil. Season with salt and pepper to taste.', 'images/broccoli-mozzarella-calzones/step-4.jpg', 'images/broccoli-mozzarella-calzones/step-4@2x.jpg'),
(4, 5, 'Make the tomato sauce', 'While the calzones continue to bake, in the pan used to cook the broccoli, heat 2 teaspoons of olive oil on medium-high until hot. Add the remaining chopped garlic; cook, stirring constantly, 30 seconds to 1 minute, or until fragrant. Add the tomato sauce and remaining Italian seasoning. Cook, stirring frequently, 2 to 3 minutes, or until slightly thickened. Turn off the heat and season with salt and pepper to taste.', 'images/broccoli-mozzarella-calzones/step-5.jpg', 'images/broccoli-mozzarella-calzones/step-5@2x.jpg'),
(4, 6, 'Make the salad & serve your dish', 'Just before serving, add the chopped olives and lettuce to the bowl of dressing. Toss to coat; season with salt and pepper to taste. Cut the baked calzones in half. Serve with the sauce and salad on the side. Garnish with the remaining parmesan cheese. Enjoy!', 'images/broccoli-mozzarella-calzones/step-6.jpg', 'images/broccoli-mozzarella-calzones/step-6@2x.jpg'),
(5, 1, 'Prepare the ingredients', 'Heat a large pot of salted water to boiling on high. Wash and dry the fresh produce. Cut off and discard the bottom 1/2 inch of the broccoli stem; cut the broccoli into small pieces, keeping the florets intact. Peel and finely chop the garlic.', 'images/bucatini-alfredo/step-1.jpg', 'images/bucatini-alfredo/step-1@2x.jpg'),
(5, 2, 'Cook the broccoli', 'In a large pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the broccoli pieces; season with salt and pepper. Cook, stirring occasionally, 4 to 5 minutes, or until slightly softened. Add 1/2 cup of water; season with salt and pepper. Cover the pan with aluminum foil and cook 3 to 4 minutes, or until the broccoli has softened and the water has cooked off. Transfer to a bowl. Wipe out the pan.', 'images/bucatini-alfredo/step-2.jpg', 'images/bucatini-alfredo/step-2@2x.jpg'),
(5, 3, 'Cook the pasta', 'While the broccoli cooks, add the pasta to the pot of boiling water and cook 8 to 10 minutes, or until al dente (still slightly firm to the bite). Reserving ½ cup of the pasta cooking water, drain thoroughly.', 'images/bucatini-alfredo/step-3.jpg', 'images/bucatini-alfredo/step-3@2x.jpg'),
(5, 4, 'Make the sauce', 'In the same pan, heat 1 1/2 tablespoons of olive oil on medium-high until hot. Add the chopped garlic; season with salt and pepper. Cook, stirring constantly, 30 seconds to 1 minute, or until fragrant. Add the flour and as much of the red pepper flakes as you\'d like, depending on how spicy you\'d like the dish to be. Cook, stirring constantly, 30 seconds to 1 minute, or until thoroughly combined. Add the heavy cream (shaking the bottle just before opening), verjus, and 1 1/4 cups of water; season with salt and pepper. Cook, whisking frequently, 2 to 3 minutes, or until thickened; season with salt and pepper to taste.', 'images/bucatini-alfredo/step-4.jpg', 'images/bucatini-alfredo/step-4@2x.jpg'),
(5, 5, 'Finish & serve your dish', 'Add the cooked pasta, cooked broccoli, crème fraîche, and half the reserved pasta cooking water to the pan. Cook, stirring vigorously, 30 seconds to 1 minute, or until the pasta is thoroughly coated. (If the sauce seems dry, gradually add the remaining pasta cooking water to achieve your desired consistency.) Turn off the heat and season with salt and pepper to taste. Garnish the finished pasta with the cheese; season with pepper. Enjoy!', 'images/bucatini-alfredo/step-5.jpg', 'images/bucatini-alfredo/step-5@2x.jpg'),
(6, 1, 'Prepare & roast the broccoli', 'Place an oven rack in the center of the oven, then preheat to 450°F. Heat a large pot of salted water to boiling on high. Wash and dry the fresh produce. Cut off and discard the bottom 1/2 inch of the broccoli stem; cut the broccoli into small pieces. Place on a sheet pan. Drizzle with olive oil and season with salt, pepper, and up to half the Italian seasoning (you will have extra); toss to coat. Arrange in an even layer. Roast 22 to 24 minutes, or until browned and tender when pierced with a fork. Remove from the oven.', 'images/bucatini-tomato-sauce/step-1.jpg', 'images/bucatini-tomato-sauce/step-1@2x.jpg'),
(6, 2, 'Prepare the remaining ingredients', 'While the broccoli roasts, peel and roughly chop the garlic. Using the flat side of your knife, smash the olives; remove and discard the pits, then roughly chop. Grate the cheese on the small side of a box grater.', 'images/bucatini-tomato-sauce/step-2.jpg', 'images/bucatini-tomato-sauce/step-2@2x.jpg'),
(6, 3, 'Cook the pasta', 'While the broccoli continues to roast, add the pasta to the pot of boiling water and cook 8 to 10 minutes, or until al dente (still slightly firm to the bite). Turn off the heat. Reserving 1/2 cup of the pasta cooking water, drain thoroughly and return to the pot.', 'images/bucatini-tomato-sauce/step-3.jpg', 'images/bucatini-tomato-sauce/step-3@2x.jpg'),
(6, 4, 'Make the sauce', 'While the pasta cooks, in a medium pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the chopped garlic, capers, and as much of the red pepper flakes as you\'d like, depending on how spicy you\'d like the dish to be; season with salt and pepper. Cook, stirring constantly, 30 seconds to 1 minute, or until fragrant. Add the tomatoes and chopped olives; season with salt and pepper. Cook, stirring occasionally and gently crushing the tomatoes with the back of a spoon, 6 to 7 minutes, or until thickened. Turn off the heat and season with salt and pepper to taste.', 'images/bucatini-tomato-sauce/step-4.jpg', 'images/bucatini-tomato-sauce/step-4@2x.jpg'),
(6, 5, 'Finish & serve your dish', 'To the pot of cooked pasta, add the roasted broccoli, sauce, butter, half the grated cheese, and half the reserved pasta cooking water; season with salt and pepper. Cook on medium-high, stirring vigorously, 1 to 2 minutes, or until the pasta is thoroughly coated. (If the sauce seems dry, gradually add the remaining pasta cooking water to achieve your desired consistency.) Turn off the heat and season with salt and pepper to taste. Garnish the finished pasta with the remaining grated cheese. Enjoy!', 'images/bucatini-tomato-sauce/step-5.jpg', 'images/bucatini-tomato-sauce/step-5@2x.jpg'),
(7, 1, 'Cook the rice', 'Place an oven rack in the center of the oven, then preheat to 450°F. In a medium pot, combine the rice, half the spice blend, a big pinch of salt, and 1 1/2 cups of water. Heat to boiling on high. Once boiling, cover and reduce the heat to low. Cook 12 to 14 minutes, or until the water has been absorbed and the rice is tender. Turn off the heat and fluff with a fork. Transfer to a large bowl and set aside in a warm place.', 'images/cheesy-enchiladas-rojas/step-1.jpg', 'images/cheesy-enchiladas-rojas/step-1@2x.jpg'),
(7, 2, 'Prepare the ingredients & make the lime sour cream', 'While the rice cooks, wash and dry the fresh produce. Thinly slice the mushrooms. Remove and discard the stems of the kale; roughly chop the leaves. Peel and roughly chop the garlic. Peel and thinly slice the onion. Place the tomatoes in a bowl; gently break apart with your hands. Grate the cheese on the large side of a box grater. Thinly slice the chives. Halve the lime crosswise. In a bowl, combine the sour cream, the juice of 1 lime half, and a drizzle of olive oil; season with salt and pepper to taste.', 'images/cheesy-enchiladas-rojas/step-2.jpg', 'images/cheesy-enchiladas-rojas/step-2@2x.jpg'),
(7, 3, 'Cook the vegetables & start the filling', 'In a large pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the sliced mushrooms in an even layer. Cook, without stirring, 2 to 3 minutes, or until lightly browned. Add the chopped kale and 1/2 cup of water; season with salt and pepper. Cook, stirring frequently, 4 to 5 minutes, or until the kale has wilted and the water has cooked off. Transfer to the bowl of cooked rice; stir to combine. Wipe out the pan.', 'images/cheesy-enchiladas-rojas/step-3.jpg', 'images/cheesy-enchiladas-rojas/step-3@2x.jpg'),
(7, 4, 'Make the sauce', 'In the same pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the chopped garlic and sliced onion; season with salt and pepper. Cook, stirring frequently, 4 to 5 minutes, or until softened. Add the chile paste and remaining spice blend; cook, stirring constantly, 30 seconds to 1 minute, or until dark red and fragrant. Add the tomatoes; season with salt and pepper. Cook, stirring frequently, 6 to 7 minutes, or until thickened. Turn off the heat. Season with salt and pepper to taste.', 'images/cheesy-enchiladas-rojas/step-4.jpg', 'images/cheesy-enchiladas-rojas/step-4@2x.jpg'),
(7, 5, 'Finish the filling & assemble the enchiladas', 'Add half the cheese and the juice of the remaining lime half to the bowl of filling. Stir to combine; season with salt and pepper to taste. Place the tortillas on a work surface. Spread about half the sauce into the bottom of a baking dish. Divide the finished filling among the tortillas; tightly roll up each tortilla around the filling. Transfer to the baking dish in a single layer, seam side down. Evenly top with the remaining sauce and remaining cheese.', 'images/cheesy-enchiladas-rojas/step-5.jpg', 'images/cheesy-enchiladas-rojas/step-5@2x.jpg'),
(7, 6, 'Bake the enchiladas & serve your dish', 'Bake the enchiladas 10 to 12 minutes, or until the cheese has melted. Remove from the oven and let stand for at least 2 minutes. Garnish with the sliced chives. Serve with the lime sour cream. Enjoy!', 'images/cheesy-enchiladas-rojas/step-6.jpg', 'images/cheesy-enchiladas-rojas/step-6@2x.jpg'),
(8, 1, 'Prepare & roast the sweet potatoes', 'Place an oven rack in the center of the oven, then preheat to 450°F. Wash and dry the fresh produce. Cut the sweet potatoes lengthwise into 1-inch-wide wedges. Place on a sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer, skin side down. Roast 27 to 29 minutes, or until browned and tender when pierced with a fork. Reserving the sheet pan, transfer to a plate and set aside in a warm place.', 'images/crispy-fish-sandwiches/step-1.jpg', 'images/crispy-fish-sandwiches/step-1@2x.jpg'),
(8, 2, 'Prepare the remaining ingredients & make the sauce', 'While the sweet potatoes roast, cut off and discard the root end of the lettuce; thinly slice the leaves. Halve the rolls. In a bowl, combine the mayonnaise, creamy mustard sauce, and sweet pickle relish. Season with salt and pepper to taste. Pat the fish fillets dry with paper towels. Halve crosswise.', 'images/crispy-fish-sandwiches/step-2.jpg', 'images/crispy-fish-sandwiches/step-2@2x.jpg'),
(8, 3, 'Bread the fish', 'While the sweet potatoes continue to roast, season the halved fish fillets on both sides with salt, pepper, and the spice blend. Crack the eggs into a bowl; season with salt and pepper. Beat until smooth. Place the breadcrumbs on a plate; season with salt and pepper. Working one piece at a time, thoroughly coat the seasoned fillets in the beaten eggs (letting any excess drip off), then in the breadcrumbs (pressing to adhere). Transfer to a separate plate.', 'images/crispy-fish-sandwiches/step-3.jpg', 'images/crispy-fish-sandwiches/step-3@2x.jpg'),
(8, 4, 'Cook the fish', 'While the sweet potatoes continue to roast, in a large pan (nonstick, if you have one), heat a thin layer of oil on medium-high until hot. Once the oil is hot enough that a pinch of breadcrumbs sizzles immediately when added, working in batches if necessary, add the breaded fish fillets. Cook 2 to 3 minutes per side, or until browned and cooked through. (If the pan seems dry, add 1 teaspoon of olive oil before flipping.) Transfer to a paper towel-lined plate; immediately season with salt and pepper.', 'images/crispy-fish-sandwiches/step-4.jpg', 'images/crispy-fish-sandwiches/step-4@2x.jpg'),
(8, 5, 'Toast the rolls', 'While the fish cooks, place the rolls on the same sheet pan, cut side up. Drizzle with olive oil. Toast in the oven 4 to 5 minutes, or until lightly browned. Transfer to a clean work surface.', 'images/crispy-fish-sandwiches/step-5.jpg', 'images/crispy-fish-sandwiches/step-5@2x.jpg'),
(8, 6, 'Assemble the sandwiches & serve your dish', 'Divide the sauce, cooked fish fillets, and sliced lettuce among the toasted rolls. Serve the sandwiches with the roasted sweet potatoes on the side. Enjoy!', 'images/crispy-fish-sandwiches/step-6.jpg', 'images/crispy-fish-sandwiches/step-6@2x.jpg'),
(9, 1, 'Cook the rice', 'Remove the honey from the refrigerator to bring to room temperature. In a medium saucepan, combine the rice, a big pinch of salt, and 1 1/2 cups of water; heat to boiling on high. Once boiling, cover and reduce the heat to low. Cook 12 to 14 minutes, or until the water has been absorbed and the rice is tender. Turn off the heat and fluff with a fork. Cover to keep warm.', 'images/general-tsos-chicken/step-1.jpg', 'images/general-tsos-chicken/step-1@2x.jpg'),
(9, 2, 'Coat & cook the chicken', 'While the rice cooks, pat the chicken dry with paper towels. Place in a large bowl and season with salt and pepper. Add the cornstarch; toss to thoroughly coat. In a medium pan, heat a thin layer of oil on medium-high until hot. Once the oil is hot enough that a piece of chicken sizzles immediately when added to the pan, add the coated chicken in an even layer (tapping off any excess cornstarch before adding). Cook, without stirring, 3 to 4 minutes, or until lightly browned. Continue to cook, stirring occasionally, 3 to 4 minutes, or until browned and cooked through. Leaving any browned bits (or fond) in the pan, transfer to a plate. Set aside in a warm place.', 'images/general-tsos-chicken/step-2.jpg', 'images/general-tsos-chicken/step-2@2x.jpg'),
(9, 3, 'Prepare the ingredients & make the sauce', 'While the chicken cooks, wash and dry the fresh produce. Cut off and discard the root end of the bok choy; roughly chop. Peel and finely chop the ginger. Peel and roughly chop the garlic. In a bowl, combine the hoisin sauce, vinegar, honey (kneading the packet before opening), sesame oil, 1 tablespoon of water, and as much of the sriracha as you\'d like, depending on how spicy you\'d like the dish to be.', 'images/general-tsos-chicken/step-3.jpg', 'images/general-tsos-chicken/step-3@2x.jpg'),
(9, 4, 'Cook the vegetables & add the sauce', 'Add the chopped bok choy, ginger, and garlic to the pan of reserved fond; season with salt and pepper. (If the pan seems dry, add 1 tablespoon of olive oil.) Cook on medium-high, stirring frequently, 2 to 3 minutes, or until softened and fragrant. Add the sauce and cook, stirring constantly and scraping up any fond, 30 seconds to 1 minute, or until thoroughly combined.', 'images/general-tsos-chicken/step-4.jpg', 'images/general-tsos-chicken/step-4@2x.jpg'),
(9, 5, 'Finish & serve your dish', 'Turn off the heat and add the cooked chicken to the pan; stir to thoroughly coat. Season with salt and pepper to taste. Serve the finished chicken and bok choy with the cooked rice. Enjoy!', 'images/general-tsos-chicken/step-5.jpg', 'images/general-tsos-chicken/step-5@2x.jpg'),
(10, 1, 'Prepare the ingredients', 'Fill a medium pot with water; add a pinch of salt. Heat to boiling on high. Wash and dry the fresh produce. Peel and finely chop the ginger. Cut out and discard the core of the cabbage; thinly slice the leaves. Peel the carrots and thinly slice into rounds. Thinly slice the chives.', 'images/hoisin-glazed-pork-chops/step-1.jpg', 'images/hoisin-glazed-pork-chops/step-1@2x.jpg'),
(10, 2, 'Cook the vegetables', 'In a large pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the chopped ginger, sliced cabbage, and sliced carrots; season with salt and pepper. Cook, stirring occasionally, 4 to 5 minutes, or until softened and fragrant. Transfer to a bowl and cover with aluminum foil to keep warm. Rinse and wipe out the pan.', 'images/hoisin-glazed-pork-chops/step-2.jpg', 'images/hoisin-glazed-pork-chops/step-2@2x.jpg'),
(10, 3, 'Cook & glaze the pork chops', 'Pat the pork chops dry with paper towels; season with salt and pepper on both sides. In the same pan, heat 1 tablespoon of olive oil on medium-high until hot. Add the seasoned pork chops and cook 3 to 5 minutes on the first side, or until browned. Flip and cook 2 to 3 minutes, or until lightly browned. Add the hoisin sauce and 1/4 cup of water. Cook, frequently spooning the glaze over the pork, 2 to 3 minutes, or until the pork chops are coated and cooked through. Turn off the heat.', 'images/hoisin-glazed-pork-chops/step-3.jpg', 'images/hoisin-glazed-pork-chops/step-3@2x.jpg'),
(10, 4, 'Make the sauce', 'While the pork chops cook, in a bowl, whisk together the soy sauce, tahini, vinegar, and as much of the sambal oelek as you\'d like, depending on how spicy you\'d like the dish to be. Season with salt and pepper to taste.', 'images/hoisin-glazed-pork-chops/step-4.jpg', 'images/hoisin-glazed-pork-chops/step-4@2x.jpg'),
(10, 5, 'Cook the noodles', 'While the pork chops continue to cook, using your hands, carefully separate the noodles and add to the pot of boiling water; cook, stirring occasionally, 2 to 4 minutes, or until tender. Turn off the heat. Drain thoroughly and return to the pot.', 'images/hoisin-glazed-pork-chops/step-5.jpg', 'images/hoisin-glazed-pork-chops/step-5@2x.jpg'),
(10, 6, 'Finish the noodles & serve your dish', 'Add the cooked vegetables, sauce, and ¼ cup of water to the pot of cooked noodles. Cook on medium-high, stirring constantly, 30 seconds to 1 minute, or until thoroughly combined. Turn off the heat. Season with salt and pepper to taste. Serve the finished noodles topped with the glazed pork chops (including any glaze from the pan). Garnish with the sliced chives. Enjoy!', 'images/hoisin-glazed-pork-chops/step-6.jpg', 'images/hoisin-glazed-pork-chops/step-6@2x.jpg'),
(11, 1, 'Prepare the ingredients', 'Remove the honey from the refrigerator to bring to room temperature. Place an oven rack in the center of the oven, then preheat to 450°F. Wash and dry the fresh produce. Halve the potatoes lengthwise; cut crosswise into 1/4-inch pieces. Peel the carrots; halve lengthwise, then cut crosswise into 1/2-inch pieces. Cut off and discard the ends of the radishes; quarter lengthwise, then halve crosswise. Quarter and deseed the lemon. Peel and finely chop the garlic; using the flat side of your knife, smash until it resembles a paste (or use a zester). Roughly chop the parsley leaves and stems.', 'images/honey-butter-barramundi/step-1.jpg', 'images/honey-butter-barramundi/step-1@2x.jpg'),
(11, 2, 'Roast the vegetables', 'Place the sliced potatoes and carrot pieces on a sheet pan. Drizzle with 1 tablespoon of olive oil; season with salt, pepper, and the za\'atar seasoning. Toss to coat. Arrange in an even layer on one side of the sheet pan. Roast 12 to 14 minutes, or until lightly browned. Leaving the oven on, remove from the oven. Place the radish pieces in a bowl. Drizzle with olive oil and season with salt and pepper; toss to coat. Carefully arrange on the other side of the sheet pan. Roast 10 to 12 minutes, or until tender when pierced with a fork. Remove from the oven. Evenly top with the juice of 2 lemon wedges.', 'images/honey-butter-barramundi/step-2.jpg', 'images/honey-butter-barramundi/step-2@2x.jpg'),
(11, 3, 'Make the yogurt sauce', 'While the vegetables roast, in a bowl, combine the yogurt, the juice of the remaining lemon wedges, 1 tablespoon of olive oil, and as much of the garlic paste as you\'d like. Drizzle with olive oil and season with salt and pepper to taste.', 'images/honey-butter-barramundi/step-3.jpg', 'images/honey-butter-barramundi/step-3@2x.jpg'),
(11, 4, 'Cook the fish', 'Once the vegetables have roasted for about 10 minutes, pat the fish fillets dry with paper towels; season with salt and pepper on both sides. In a large pan (nonstick, if you have one), heat 1 tablespoon of olive oil on medium-high until hot. Add the seasoned fillets, skin side down. Cook 4 to 6 minutes on the first side, or until lightly browned. Flip and add the butter. Cook, frequently spooning the butter over the fillets, 2 to 3 minutes, or until the fish is cooked through. Leaving the melted butter and any browned bits (or fond) in the pan, transfer the cooked fillets to a plate.', 'images/honey-butter-barramundi/step-4.jpg', 'images/honey-butter-barramundi/step-4@2x.jpg'),
(11, 5, 'Make the pan sauce', 'Add the honey (kneading the packet before opening) and 2 tablespoons of water to the pan of melted butter (be careful, as the liquid may splatter). Cook on medium-high, stirring frequently and scraping up any fond, 30 seconds to 1 minute, or until slightly thickened. Turn off the heat and season with salt and pepper to taste.', 'images/honey-butter-barramundi/step-5.jpg', 'images/honey-butter-barramundi/step-5@2x.jpg'),
(11, 6, 'Serve your dish', 'Serve the cooked fish fillets and roasted vegetables with the yogurt sauce on the side. Top the fish with the pan sauce. Garnish with the chopped parsley. Enjoy!', 'images/honey-butter-barramundi/step-6.jpg', 'images/honey-butter-barramundi/step-6@2x.jpg'),
(12, 1, 'Prepare the ingredients', 'Preheat the oven to 425°F. Wash and dry the fresh produce. Peel and roughly chop the garlic. Peel and thinly slice the shallot. Remove and discard the stems of the kale; roughly chop the leaves. Quarter and deseed the lemon.', 'images/kale-ricotta-quiche/step-1.jpg', 'images/kale-ricotta-quiche/step-1@2x.jpg'),
(12, 2, 'Cook the kale', 'In a large pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the chopped garlic and sliced shallot; season with salt and pepper. Cook, stirring occasionally, 1 to 2 minutes, or until softened and fragrant. Add the chopped kale, heavy cream (shaking the bottle just before opening), and 1/4 cup of water; season with salt and pepper. Cook, stirring occasionally, 4 to 5 minutes, or until the kale has wilted and most of the liquid has cooked off. Turn off the heat. Season with salt and pepper to taste.', 'images/kale-ricotta-quiche/step-2.jpg', 'images/kale-ricotta-quiche/step-2@2x.jpg'),
(12, 3, 'Make the filling', 'Crack the eggs into a large bowl. Add the ricotta cheese, the juice of 1 lemon wedge, and the spice blend; season with salt and pepper. Whisk to thoroughly combine. Stir in the cooked kale.', 'images/kale-ricotta-quiche/step-3.jpg', 'images/kale-ricotta-quiche/step-3@2x.jpg'),
(12, 4, 'Assemble & bake the quiche', 'Place the pie crust on a sheet pan, leaving it in its tin. Carefully pour the filling into the crust; season with salt and pepper. Bake 24 to 26 minutes, or until the crust is browned and the filling is set and cooked through. Remove from the oven. Let stand for at least 5 minutes before serving.', 'images/kale-ricotta-quiche/step-4.jpg', 'images/kale-ricotta-quiche/step-4@2x.jpg'),
(12, 5, 'Prepare the remaining ingredients', 'While the quiche bakes, quarter and core the apple; thinly slice lengthwise. Place in a bowl and top with the juice of 1 lemon wedge to prevent browning. Cut off and discard the root end of the lettuce; roughly chop the leaves. To make the dressing, in a large bowl, combine the crème fraîche, the juice of the remaining lemon wedges, and a drizzle of olive oil. Season with salt and pepper to taste.', 'images/kale-ricotta-quiche/step-5.jpg', 'images/kale-ricotta-quiche/step-5@2x.jpg'),
(12, 6, 'Make the salad & serve your dish', 'Just before serving, add the sliced apple and chopped lettuce to the bowl of dressing. Toss to combine; season with salt and pepper to taste. Serve the baked quiche with the salad on the side. Garnish the salad with the almonds. Enjoy!', 'images/kale-ricotta-quiche/step-6.jpg', 'images/kale-ricotta-quiche/step-6@2x.jpg'),
(13, 1, 'Prepare & roast the sweet potato', 'Place an oven rack in the center of the oven, then preheat to 450°F. Wash and dry the fresh produce. Medium dice the sweet potato. Place on a sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer. Roast 20 to 22 minutes, or until browned and tender when pierced with a fork. Remove from the oven.', 'images/mexican-spiced-barramundi/step-1.jpg', 'images/mexican-spiced-barramundi/step-1@2x.jpg'),
(13, 2, 'Prepare the remaining ingredients', 'While the sweet potato roasts, remove and discard the stems of the kale; finely chop the leaves and place in a large bowl. Using a peeler, remove the green rind of the lime, avoiding the white pith; mince to get 1 teaspoon of zest (or use a zester). Quarter the lime. Halve the orange; squeeze the juice into a bowl, straining out any seeds. Peel and finely chop the garlic; using the flat side of your knife, smash until it resembles a paste (or use a zester). Halve and pit the avocado.', 'images/mexican-spiced-barramundi/step-2.jpg', 'images/mexican-spiced-barramundi/step-2@2x.jpg'),
(13, 3, 'Make the dressing & marinate the kale', 'Scoop the flesh of half the avocado into the bowl of orange juice. Add the lime zest, the juice of 2 lime wedges, as much of the garlic paste as you\'d like, and 1 tablespoon of olive oil. Mash and whisk until smooth; season with salt and pepper. Add the dressing to the bowl of chopped kale. Using your hands, massage the dressing into the kale for 1 to 2 minutes, or until the leaves have softened slightly. Set aside to marinate, stirring occasionally, for at least 10 minutes.', 'images/mexican-spiced-barramundi/step-3.jpg', 'images/mexican-spiced-barramundi/step-3@2x.jpg'),
(13, 4, 'Toast the pepitas', 'While the kale marinates, heat a large pan (nonstick, if you have one) on medium-high until hot. Add the pepitas and toast, stirring frequently, 1 to 2 minutes, or until lightly browned and fragrant. Transfer to a plate. Wipe out the pan.', 'images/mexican-spiced-barramundi/step-4.jpg', 'images/mexican-spiced-barramundi/step-4@2x.jpg'),
(13, 5, 'Season & cook the fish', 'Pat the fish fillets dry with paper towels. Season on both sides with salt, pepper, and the spice blend. In the same pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the seasoned fillets, skin side down. Cook 4 to 6 minutes on the first side, or until the skin is crispy. Flip and cook 1 to 3 minutes, or until cooked through. Transfer to a plate.', 'images/mexican-spiced-barramundi/step-5.jpg', 'images/mexican-spiced-barramundi/step-5@2x.jpg'),
(13, 6, 'Finish the salad & serve your dish', 'Medium dice the remaining avocado half. Add the roasted sweet potato, diced avocado, and toasted pepitas to the bowl of marinated kale. Gently toss to combine; season with salt and pepper to taste. Serve the cooked fish over the finished salad, with the remaining lime wedges on the side. Enjoy!', 'images/mexican-spiced-barramundi/step-6.jpg', 'images/mexican-spiced-barramundi/step-6@2x.jpg'),
(14, 1, 'Prepare & roast the vegetables', 'Preheat the oven to 450°F. Wash and dry the fresh produce. Quarter the mushrooms. Quarter the potatoes lengthwise, then cut crosswise into 1/2-inch pieces. Place the vegetables on a sheet pan. Drizzle with olive oil and season with salt, pepper, and 3/4 of the spice blend; toss to coat. Arrange in an even layer. Roast 21 to 23 minutes, or until browned and tender when pierced with a fork. Remove from the oven.', 'images/mushroom-potato-tacos/step-1.jpg', 'images/mushroom-potato-tacos/step-1@2x.jpg'),
(14, 2, 'Prepare the remaining ingredients', 'While the vegetables roast, roughly chop the piquante peppers. Peel and small dice the shallot. Cut off and discard the root end of the lettuce; roughly chop the leaves. Peel and medium dice the orange. Cut off and discard the ends of the radishes; halve lengthwise, then thinly slice crosswise. Roughly chop the jalapeño pepper; thoroughly wash your hands and cutting board immediately after handling. In a bowl, combine the sour cream, a drizzle of olive oil, and as much of the remaining spice blend as you\'d like (you may have extra). Season with salt and pepper to taste.', 'images/mushroom-potato-tacos/step-2.jpg', 'images/mushroom-potato-tacos/step-2@2x.jpg'),
(14, 3, 'Warm the tortillas', 'While the vegetables continue to roast, place the tortillas on a large piece of aluminum foil. Tightly wrap to seal. Place directly onto the oven rack and warm 5 to 7 minutes, or until heated through and pliable. Transfer to a work surface and carefully unwrap.', 'images/mushroom-potato-tacos/step-3.jpg', 'images/mushroom-potato-tacos/step-3@2x.jpg'),
(14, 4, 'Make the pepper relish', 'While the tortillas warm, in a medium bowl, combine the chopped piquante peppers, diced shallot, half the vinegar, and as much of the chopped jalapeño pepper as you\'d like, depending on how spicy you\'d like the dish to be. Drizzle with olive oil and season with salt and pepper to taste.', 'images/mushroom-potato-tacos/step-4.jpg', 'images/mushroom-potato-tacos/step-4@2x.jpg'),
(14, 5, 'Make the salad', 'While the tortillas continue to warm, in a medium bowl, combine the chopped lettuce, diced orange, sliced radishes, peanuts, and remaining vinegar. Drizzle with olive oil and season with salt and pepper to taste.', 'images/mushroom-potato-tacos/step-5.jpg', 'images/mushroom-potato-tacos/step-5@2x.jpg'),
(14, 6, 'Assemble the tacos & serve your dish', 'Spread a layer of the seasoned sour cream onto the warmed tortillas. Top with the roasted vegetables and pepper relish. Serve the tacos with the salad on the side. Enjoy!', 'images/mushroom-potato-tacos/step-6.jpg', 'images/mushroom-potato-tacos/step-6@2x.jpg'),
(15, 1, 'Prepare the ingredients', 'Place an oven rack in the center of the oven, then preheat to 450°F. Heat a medium pot of salted water to boiling on high. Wash and dry the fresh produce. Cut off and discard the bottom 1/2 inch of the broccoli stem; cut the broccoli into small pieces, keeping the florets intact. Quarter and deseed the lemon. Peel and medium dice the sweet potatoes.', 'images/parmesan-crusted-chicken/step-1.jpg', 'images/parmesan-crusted-chicken/step-1@2x.jpg'),
(15, 2, 'Roast the broccoli', 'Place the broccoli pieces on a sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer. Roast 16 to 18 minutes, or until browned and tender when pierced with a fork. Remove from the oven. Evenly top with the juice of 2 lemon wedges.', 'images/parmesan-crusted-chicken/step-2.jpg', 'images/parmesan-crusted-chicken/step-2@2x.jpg'),
(15, 3, 'Cook & mash the sweet potatoes', 'While the broccoli roasts, add the diced sweet potatoes to the pot of boiling water. Cook 14 to 16 minutes, or until tender when pierced with a fork. Turn off the heat. Drain thoroughly and return to the pot. Add the butter and a drizzle of olive oil. Using a fork, mash to your desired consistency; season with salt and pepper to taste. Cover to keep warm.', 'images/parmesan-crusted-chicken/step-3.jpg', 'images/parmesan-crusted-chicken/step-3@2x.jpg'),
(15, 4, 'Coat the chicken', 'While the sweet potatoes cook, on a large plate, combine the flour, half the cheese, and all but a pinch of the spice blend; season with salt and pepper. Pat the chicken dry with paper towels; season with salt and pepper on both sides. Working one piece at a time, thoroughly coat the seasoned chicken in the flour mixture (tapping off any excess). Transfer to a separate plate.', 'images/parmesan-crusted-chicken/step-4.jpg', 'images/parmesan-crusted-chicken/step-4@2x.jpg'),
(15, 5, 'Cook the chicken', 'While the sweet potatoes continue to cook, in a large pan (nonstick, if you have one), heat 2 teaspoons of olive oil on medium-high until hot. Add the coated chicken and cook 5 to 7 minutes per side, or until golden brown and cooked through. Turn off the heat.', 'images/parmesan-crusted-chicken/step-5.jpg', 'images/parmesan-crusted-chicken/step-5@2x.jpg'),
(15, 6, 'Make the sauce & serve your dish', 'While the chicken cooks, in a bowl, combine the mayonnaise, remaining spice blend, and the juice of the remaining lemon wedges; season with salt and pepper to taste. Serve the cooked chicken, roasted broccoli, and mashed sweet potatoes with the sauce on the side. Garnish the chicken with the remaining cheese. Enjoy!', 'images/parmesan-crusted-chicken/step-6.jpg', 'images/parmesan-crusted-chicken/step-6@2x.jpg'),
(16, 1, 'Prepare & roast the sweet potato', 'Place an oven rack in the center of the oven, then preheat to 450°F. Wash and dry the fresh produce. Cut the sweet potato lengthwise into 1-inch wedges. Transfer to a sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer, skin side down. Roast 21 to 23 minutes, or until browned and tender when pierced with a fork. Set aside in a warm place.', 'images/pimento-cheeseburgers/step-1.jpg', 'images/pimento-cheeseburgers/step-1@2x.jpg'),
(16, 2, 'Prepare the remaining ingredients', 'While the sweet potato roasts, grate the cheese on the large side of a box grater. Place in a medium bowl. Finely chop the peppers. Halve the buns.', 'images/pimento-cheeseburgers/step-2.jpg', 'images/pimento-cheeseburgers/step-2@2x.jpg'),
(16, 3, 'Make the pimento cheese', 'While the sweet potato continues to roast, add the mayonnaise, spice blend, and peppers to the bowl of cheese. Stir to thoroughly combine; season with salt and pepper to taste.', 'images/pimento-cheeseburgers/step-3.jpg', 'images/pimento-cheeseburgers/step-3@2x.jpg'),
(16, 4, 'Form & cook the patties', 'While the sweet potato continues to roast, place the ground beef in a bowl; season with salt and pepper. Gently mix to incorporate. Using your hands, form the mixture into two ¾-inch-thick patties; transfer to a plate. In a medium pan (nonstick, if you have one), heat 1 teaspoon of olive oil on medium-high until hot. Add the patties and cook 3 to 4 minutes per side for medium-rare, or until browned and cooked to your desired degree of doneness. Leaving any browned bits (or fond) in the pan, transfer to a plate.', 'images/pimento-cheeseburgers/step-4.jpg', 'images/pimento-cheeseburgers/step-4@2x.jpg'),
(16, 5, 'Toast the buns', 'While the sweet potato continues to roast, add the buns, cut side down, to the pan of reserved fond. Toast on medium-high 30 seconds to 1 minute, or until lightly browned. Transfer to a work surface.', 'images/pimento-cheeseburgers/step-5.jpg', 'images/pimento-cheeseburgers/step-5@2x.jpg'),
(16, 6, 'Assemble the burgers & plate your dish', 'Divide half the pimento cheese between the bottoms of the toasted buns. Top with the cooked patties and remaining pimento cheese. Complete the burgers with the bun tops. Divide the burgers and roasted sweet potato between 2 dishes. Enjoy!', 'images/pimento-cheeseburgers/step-6.jpg', 'images/pimento-cheeseburgers/step-6@2x.jpg'),
(17, 1, 'Prepare & roast the potatoes', 'Preheat the oven to 450°F. Wash and dry the fresh produce. Halve the potatoes lengthwise, then cut crosswise into 1/4-inch pieces. Place on a sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer. Roast 22 to 24 minutes, or until browned and tender when pierced with a fork. Carefully transfer to a large bowl.', 'images/pork-chorizo-tacos/step-1.jpg', 'images/pork-chorizo-tacos/step-1@2x.jpg'),
(17, 2, 'Prepare the remaining ingredients', 'While the potatoes roast, cut out and discard the core of the cabbage; thinly slice the leaves. Halve the orange; squeeze the juice into a bowl, straining out any seeds. Cut off and discard the ends of the radishes; halve lengthwise, then thinly slice crosswise. Peel and finely chop the garlic; using the flat side of your knife, smash until it resembles a paste (or use a zester). Quarter the lime. In a bowl, combine the crème fraîche and the juice of 1 lime wedge. Drizzle with olive oil and season with salt and pepper to taste.', 'images/pork-chorizo-tacos/step-2.jpg', 'images/pork-chorizo-tacos/step-2@2x.jpg'),
(17, 3, 'Make the filling', 'While the potatoes continue to roast, in a medium pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the ground chorizo; season with salt and pepper. Cook, frequently breaking the meat apart with a spoon, 3 to 5 minutes, or until browned. Add the sliced cabbage; season with salt and pepper. Cook, stirring occasionally, 2 to 3 minutes, or until slightly softened. Add the orange juice and 1/2 cup of water; season with salt and pepper. Cook, stirring occasionally, 6 to 7 minutes, or until the cabbage has softened and the chorizo is cooked through. Turn off the heat and stir in the juice of 2 lime wedges; season with salt and pepper to taste.', 'images/pork-chorizo-tacos/step-3.jpg', 'images/pork-chorizo-tacos/step-3@2x.jpg'),
(17, 4, 'Warm the tortillas & season the radishes', 'While the filling cooks, place the tortillas on a large piece of aluminum foil and tightly wrap to seal. Place directly onto the oven rack and warm 5 to 7 minutes, or until heated through and pliable. Transfer to a work surface and carefully unwrap. While the tortillas warm, in a bowl, combine the sliced radishes and the juice of the remaining lime wedge. Drizzle with olive oil and season with salt and pepper.', 'images/pork-chorizo-tacos/step-4.jpg', 'images/pork-chorizo-tacos/step-4@2x.jpg'),
(17, 5, 'Finish the potatoes', 'While the tortillas continue to warm, add the cheese and as much of the garlic paste as you\'d like to the bowl of roasted potatoes. Stir to coat; season with salt and pepper to taste.', 'images/pork-chorizo-tacos/step-5.jpg', 'images/pork-chorizo-tacos/step-5@2x.jpg'),
(17, 6, 'Assemble the tacos & serve your dish', 'Divide the filling, seasoned radishes, and lime crème fraîche among the warmed tortillas. Serve the tacos with the finished potatoes on the side. Enjoy!', 'images/pork-chorizo-tacos/step-6.jpg', 'images/pork-chorizo-tacos/step-6@2x.jpg'),
(18, 1, 'Prepare & roast the vegetables', 'Place an oven rack in the center of the oven, then preheat to 450°F. Heat a medium pot of salted water to boiling on high. Heat a small pot of water to boiling on high. Wash and dry the fresh produce. Cut off and discard the bottom 1/2 inch of the broccoli stem; cut the broccoli into small pieces, keeping the florets intact. Peel and thinly slice the onion. Place the vegetables on a sheet pan. Drizzle with olive oil and season with salt, pepper, and the za\'atar seasoning; toss to coat. Arrange in an even layer. Roast 20 to 22 minutes, or until browned and tender when pierced with a fork. Remove from the oven.', 'images/roasted-broccoli-fregola-sarda-salad/step-1.jpg', 'images/roasted-broccoli-fregola-sarda-salad/step-1@2x.jpg'),
(18, 2, 'Prepare the remaining ingredients', 'While the vegetables roast, quarter and deseed the lemon. Peel and finely chop the garlic; using the flat side of your knife, smash until it resembles a paste (or use a zester). Roughly chop the almonds. Using a fork, crumble the cheese into small pieces. Pick the mint leaves off the stems; discard the stems.', 'images/roasted-broccoli-fregola-sarda-salad/step-2.jpg', 'images/roasted-broccoli-fregola-sarda-salad/step-2@2x.jpg'),
(18, 3, 'Cook the pasta', 'While the vegetables continue to roast, add the pasta to the medium pot of boiling water and cook 14 to 16 minutes, or until tender. Turn off the heat. Drain thoroughly and return to the pot.', 'images/roasted-broccoli-fregola-sarda-salad/step-3.jpg', 'images/roasted-broccoli-fregola-sarda-salad/step-3@2x.jpg'),
(18, 4, 'Cook & peel the eggs', 'While the pasta cooks, carefully add the eggs to the small pot of boiling water and cook for exactly 9 minutes. Drain and rinse under cold water for 30 seconds to 1 minute to stop the cooking process. When cool enough to handle, carefully peel the cooked eggs. Transfer to a cutting board and thinly slice into rounds; season with salt and pepper.', 'images/roasted-broccoli-fregola-sarda-salad/step-4.jpg', 'images/roasted-broccoli-fregola-sarda-salad/step-4@2x.jpg'),
(18, 5, 'Make the dressing', 'While the eggs cook, in a bowl, whisk together the tahini, the juice of all 4 lemon wedges, 2 tablespoons of water, and as much of the garlic paste as you\'d like. Slowly whisk in 2 tablespoons of olive oil until well combined; season with salt and pepper to taste.', 'images/roasted-broccoli-fregola-sarda-salad/step-5.jpg', 'images/roasted-broccoli-fregola-sarda-salad/step-5@2x.jpg'),
(18, 6, 'Finish & serve your dish', 'Add the roasted vegetables, chopped almonds, crumbled cheese, dressing, and a drizzle of olive oil to the pot of cooked pasta. Stir to combine; season with salt and pepper to taste. Serve the finished salad topped with the seasoned eggs and a drizzle of olive oil. Garnish with the mint leaves (tearing just before adding). Enjoy!', 'images/roasted-broccoli-fregola-sarda-salad/step-6.jpg', 'images/roasted-broccoli-fregola-sarda-salad/step-6@2x.jpg'),
(19, 1, 'Prepare & roast the vegetables', 'Place an oven rack in the center of the oven, then preheat to 450°F. Heat a medium pot of salted water to boiling on high. Line a sheet pan with aluminum foil. Wash and dry the fresh produce. Cut off and discard the stem ends of the Brussels sprouts; halve lengthwise. Peel the carrots; halve lengthwise, then cut crosswise into 1-inch pieces. Place the vegetables on the sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer. Roast 14 to 16 minutes, or until browned and tender when pierced with a fork. Remove from the oven.', 'images/roasted-brussels-sprout-freekeh-salad/step-1.jpg', 'images/roasted-brussels-sprout-freekeh-salad/step-1@2x.jpg'),
(19, 2, 'Cook the freekeh', 'While the vegetables roast, peel 1 garlic clove; using the flat side of your knife, gently smash to flatten. Add the smashed garlic and freekeh to the pot of boiling water. Cook, uncovered, 20 to 22 minutes, or until tender. Turn off the heat. Drain thoroughly and return to the pot.', 'images/roasted-brussels-sprout-freekeh-salad/step-2.jpg', 'images/roasted-brussels-sprout-freekeh-salad/step-2@2x.jpg'),
(19, 3, 'Prepare the remaining ingredients', 'While the freekeh cooks, using a peeler, remove the yellow rind of the lemon, avoiding the white pith; mince the rind to get 2 teaspoons of zest (or use a zester). Quarter and deseed the lemon. Peel and finely chop the remaining garlic clove; using the flat side of your knife, smash until it resembles a paste (or use a zester). Roughly chop the almonds. Pit and roughly chop the dates. Pick the mint leaves off the stems; discard the stems.', 'images/roasted-brussels-sprout-freekeh-salad/step-3.jpg', 'images/roasted-brussels-sprout-freekeh-salad/step-3@2x.jpg'),
(19, 4, 'Make the lemon yogurt', 'While the freekeh continues to cook, in a bowl, combine the yogurt, lemon zest, the juice of 1 lemon wedge, and as much of the garlic paste as you\'d like. Drizzle with olive oil and season with salt and pepper to taste.', 'images/roasted-brussels-sprout-freekeh-salad/step-4.jpg', 'images/roasted-brussels-sprout-freekeh-salad/step-4@2x.jpg'),
(19, 5, 'Finish the salad', 'To the pot of cooked freekeh, add the peppers, chopped almonds and dates, roasted vegetables, the juice of the remaining lemon wedges, half the mint leaves (tearing just before adding), and as much of the red pepper flakes as you\'d like, depending on how spicy you\'d like the dish to be. Drizzle with olive oil and stir to combine. Season with salt and pepper to taste.', 'images/roasted-brussels-sprout-freekeh-salad/step-5.jpg', 'images/roasted-brussels-sprout-freekeh-salad/step-5@2x.jpg'),
(19, 6, 'Serve your dish', 'Serve the finished salad with the lemon yogurt on the side. Garnish the salad with the cheese (crumbling before adding), remaining mint leaves (tearing just before adding), and a drizzle of olive oil. Enjoy!', 'images/roasted-brussels-sprout-freekeh-salad/step-6.jpg', 'images/roasted-brussels-sprout-freekeh-salad/step-6@2x.jpg'),
(20, 1, 'Prepare & roast the cauliflower', 'Place an oven rack in the center of the oven, then preheat to 450°F. Heat a small pot of water to boiling on high. Wash and dry the fresh produce. Cut out and discard the core of the cauliflower; cut into small pieces. Place on a sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer. Roast 22 to 24 minutes, or until lightly browned and tender when pierced with a fork. Carefully transfer to a large bowl.', 'images/roasted-cauliflower-salad/step-1.jpg', 'images/roasted-cauliflower-salad/step-1@2x.jpg'),
(20, 2, 'Prepare the remaining ingredients', 'While the cauliflower roasts, peel and thinly slice the shallot. Peel and roughly chop the garlic. Remove and discard the stems of the kale; roughly chop. Using a peeler, remove the yellow rind of the lemon, avoiding the white pith; mince the rind to get 2 teaspoons of zest (or use a zester). Quarter and deseed the lemon.', 'images/roasted-cauliflower-salad/step-2.jpg', 'images/roasted-cauliflower-salad/step-2@2x.jpg'),
(20, 3, 'Cook & peel the eggs', 'While the cauliflower continues to roast, carefully add the eggs to the pot of boiling water and cook for exactly 7 minutes. Drain and rinse under cold water for 30 seconds to 1 minute to stop the cooking process. When cool enough to handle, carefully peel the cooked eggs.', 'images/roasted-cauliflower-salad/step-3.jpg', 'images/roasted-cauliflower-salad/step-3@2x.jpg'),
(20, 4, 'Make the parmesan breadcrumbs', 'While the eggs cook, in a medium pan (nonstick, if you have one), heat 2 teaspoons of olive oil on medium-high until hot. Add the breadcrumbs; season with salt and pepper. Toast, stirring frequently, 2 to 4 minutes, or until lightly browned. Transfer to a bowl and stir in the cheese; season with salt and pepper to taste. Wipe out the pan.', 'images/roasted-cauliflower-salad/step-4.jpg', 'images/roasted-cauliflower-salad/step-4@2x.jpg'),
(20, 5, 'Cook the kale', 'In the same pan, heat 1 tablespoon of olive oil on medium-high until hot. Add the sliced shallot and chopped garlic; season with salt and pepper. Cook, stirring frequently, 1 to 2 minutes, or until softened. Add the chopped kale and ¼ cup of water; season with salt and pepper. Cook, stirring occasionally, 3 to 4 minutes, or until the kale has wilted and the water has cooked off. Turn off the heat. Stir in the lemon zest. Transfer to the bowl of roasted cauliflower. Gently stir to combine; season with salt and pepper to taste. Wipe out the pan.', 'images/roasted-cauliflower-salad/step-5.jpg', 'images/roasted-cauliflower-salad/step-5@2x.jpg'),
(20, 6, 'Make the brown butter & plate your dish', 'In the same pan, heat the butter on medium-high until melted. Cook, stirring frequently and swirling the pan, 1 to 2 minutes, or until browned and nuttily fragrant. (Be careful not to overcook, as the butter can burn easily.) Turn off the heat. Stir in the capers and the juice of all 4 lemon wedges; season with salt and pepper to taste. Top the finished cauliflower and kale with the brown butter, parmesan breadcrumbs, and peeled eggs; season the eggs with salt and pepper. Enjoy!', 'images/roasted-cauliflower-salad/step-6.jpg', 'images/roasted-cauliflower-salad/step-6@2x.jpg'),
(21, 1, 'Roast the chicken', 'Preheat the oven to 450°F. Line a sheet pan with aluminum foil. Pat the chicken dry with paper towels and place on the foil. Season on both sides with salt, pepper, and the spice blend. Drizzle with olive oil and turn to coat; arrange skin side up. Roast 36 to 38 minutes, or until browned and cooked through. (An instant-read thermometer inserted into the thickest part of the thigh should register 165ºF.) Reserving any drippings on the sheet pan, transfer to a cutting board and let rest for at least 5 minutes.', 'images/roasted-chicken-fall-vegetables/step-1.jpg', 'images/roasted-chicken-fall-vegetables/step-1@2x.jpg'),
(21, 2, 'Prepare the ingredients', 'While the chicken roasts, wash and dry the fresh produce. Medium dice the sweet potatoes. Cut off and discard the ends of the Brussels sprouts; halve lengthwise.', 'images/roasted-chicken-fall-vegetables/step-2.jpg', 'images/roasted-chicken-fall-vegetables/step-2@2x.jpg'),
(21, 3, 'Roast the vegetables', 'While the chicken continues to roast, place the sweet potatoes and Brussels sprouts on a separate sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer. Roast, stirring halfway through, 24 to 26 minutes, or until lightly browned and tender when pierced with a fork. Remove from the oven and top with the vinegar; carefully stir to coat. Set aside in a warm place.', 'images/roasted-chicken-fall-vegetables/step-3.jpg', 'images/roasted-chicken-fall-vegetables/step-3@2x.jpg'),
(21, 4, 'Prepare the remaining ingredients', 'While the vegetables roast, peel and finely chop the ginger. Roughly chop the walnuts.', 'images/roasted-chicken-fall-vegetables/step-4.jpg', 'images/roasted-chicken-fall-vegetables/step-4@2x.jpg'),
(21, 5, 'Make the compote', 'While the vegetables continue to roast, in a small saucepan, combine the cranberries, sugar, ginger, and 1/4 cup of water; season with salt and pepper. Heat to boiling on high. Once boiling, reduce the heat to medium-high. Cook, stirring occasionally, 4 to 6 minutes, or until thickened and the cranberries are mostly broken down; season with salt and pepper to taste. Transfer to a serving dish.', 'images/roasted-chicken-fall-vegetables/step-5.jpg', 'images/roasted-chicken-fall-vegetables/step-5@2x.jpg'),
(21, 6, 'Carve the chicken & serve your dish', 'Using a sharp, sturdy knife, cut along the leg of the rested chicken to separate the thigh and breast. Cut the breast in half crosswise through the bone (keeping the wing intact). Cut through the joint connecting the drumstick to the thigh. Divide the carved chicken and finished vegetables among 4 dishes. Top with any reserved drippings. Garnish with the walnuts. Serve the compote on the side. Enjoy!', 'images/roasted-chicken-fall-vegetables/step-6.jpg', 'images/roasted-chicken-fall-vegetables/step-6@2x.jpg'),
(22, 1, 'Roast the pork & broccoli', 'Place an oven rack in the center of the oven, then preheat to 450°F. Line a sheet pan with aluminum foil. Wash and dry the fresh produce. Cut off and discard the bottom 1/2 inch of the broccoli stem; cut the broccoli into large pieces, keeping the florets intact. Place on the sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer on one side of the sheet pan. Pat the pork dry with paper towels; season on all sides with salt, pepper, and the spice blend. Place on the other side of the sheet pan. Drizzle with olive oil; turn to coat. Roast, rotating the sheet pan halfway through, 26 to 28 minutes, or until the broccoli is browned and the pork is cooked through. (An instant-read thermometer inserted into the pork should register 145°F.) Remove from the oven. Transfer the roasted pork to a cutting board and let rest for at least 5 minutes.', 'images/roasted-pork-broccoli/step-1.jpg', 'images/roasted-pork-broccoli/step-1@2x.jpg'),
(22, 2, 'Prepare the ingredients', 'While the pork and broccoli roast, peel and finely chop the garlic; using the side of your knife, smash until it resembles a paste (or use a zester). Core and medium dice the apple. Small dice the cheese.', 'images/roasted-pork-broccoli/step-2.jpg', 'images/roasted-pork-broccoli/step-2@2x.jpg'),
(22, 3, 'Make the garlic breadcrumbs', 'While the pork and broccoli continue to roast, in a medium pan, heat a drizzle of olive oil on medium-high until hot. Add the breadcrumbs and half the garlic paste. Cook, stirring constantly, 2 to 3 minutes, or until golden brown. Transfer to a plate; immediately season with salt and pepper. Wipe out the pan.', 'images/roasted-pork-broccoli/step-3.jpg', 'images/roasted-pork-broccoli/step-3@2x.jpg'),
(22, 4, 'Cook the apple', 'While the pork and broccoli continue to roast, in the same pan, heat a drizzle of olive oil on medium-high until hot. Add the diced apple; season with salt and pepper. Cook, stirring occasionally, 3 to 5 minutes, or until slightly softened. Add the vinegar and cook, stirring constantly, 30 seconds to 1 minute, or until the liquid has cooked off. Transfer to a bowl; season with salt and pepper to taste. Cover with aluminum foil to keep warm. Rinse and wipe out the pan.', 'images/roasted-pork-broccoli/step-4.jpg', 'images/roasted-pork-broccoli/step-4@2x.jpg'),
(22, 5, 'Make the cheese sauce', 'While the pork rests, in the same pan, heat 1 ½ tablespoons of olive oil on medium-high until hot. Add the flour and remaining garlic paste; season with salt and pepper. Cook, stirring constantly, 30 seconds to 1 minute, or until lightly browned and fragrant. Add the milk and 1/2 cup of water; season with salt and pepper. Cook, whisking frequently, 2 to 3 minutes, or until thickened. Add the diced cheese; season with salt and pepper. Cook, whisking constantly, 1 to 2 minutes, or until the cheese has melted. Turn off the heat and season with salt and pepper to taste.', 'images/roasted-pork-broccoli/step-5.jpg', 'images/roasted-pork-broccoli/step-5@2x.jpg'),
(22, 6, 'Slice the pork & serve your dish', 'Find the lines of muscle (or grain) on the rested pork; thinly slice crosswise against the grain. Serve the sliced pork with the roasted broccoli and cheese sauce. Top the pork with the cooked apple and garlic breadcrumbs. Enjoy!', 'images/roasted-pork-broccoli/step-6.jpg', 'images/roasted-pork-broccoli/step-6@2x.jpg'),
(23, 1, 'Prepare & roast the broccoli', 'Place an oven rack in the center of the oven, then preheat to 450°F. Heat a large pot of salted water to boiling on high. Wash and dry the fresh produce. Quarter and deseed the lemon. Cut off and discard the bottom 1/2 inch of the broccoli stem; cut the broccoli into small pieces, keeping the florets intact. Place on a sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer. Roast 16 to 18 minutes, or until browned and tender when pierced when pierced with a fork. Remove from the oven. Evenly top with the juice of 2 lemon wedges.', 'images/roasted-red-pepper-pasta/step-1.jpg', 'images/roasted-red-pepper-pasta/step-1@2x.jpg'),
(23, 2, 'Cook the pasta', 'While the broccoli roasts, add the pasta to the pot of boiling water and cook 8 to 10 minutes, or until al dente (still slightly firm to the bite). Reserving ½ cup of the pasta cooking water, drain thoroughly.', 'images/roasted-red-pepper-pasta/step-2.jpg', 'images/roasted-red-pepper-pasta/step-2@2x.jpg'),
(23, 3, 'Prepare the remaining ingredients', 'While the pasta cooks, peel and roughly chop the garlic. Finely chop the peppers.', 'images/roasted-red-pepper-pasta/step-3.jpg', 'images/roasted-red-pepper-pasta/step-3@2x.jpg'),
(23, 4, 'Make the sauce', 'While the pasta continues to cook, in a medium pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the capers and chopped garlic and peppers; season with salt and pepper. Cook, stirring frequently, 2 to 3 minutes, or until lightly browned. Add the tomato paste and as much of the chile paste as you\'d like, depending on how spicy you\'d like the dish to be. Cook, stirring constantly, 1 to 2 minutes, or until dark red and fragrant. Turn off the heat; add the heavy cream (shaking the bottle just before opening) and 1/4 cup of water. Stir to combine; season with salt and pepper to taste.', 'images/roasted-red-pepper-pasta/step-4.jpg', 'images/roasted-red-pepper-pasta/step-4@2x.jpg'),
(23, 5, 'Finish the pasta & serve your dish', 'To the pan of sauce, add the cooked pasta, butter, and half the reserved pasta cooking water. Cook on medium-high, stirring vigorously, 30 seconds to 1 minute, or until the pasta is thoroughly coated. (If the sauce seems dry, gradually add the remaining pasta cooking water to achieve your desired consistency.) Turn off the heat and season with salt and pepper to taste. Serve the finished pasta with the roasted broccoli and remaining lemon wedges on the side. Garnish the pasta with the almonds and half the cheese. Garnish the broccoli with the remaining cheese. Enjoy!', 'images/roasted-red-pepper-pasta/step-5.jpg', 'images/roasted-red-pepper-pasta/step-5@2x.jpg'),
(24, 1, 'Prepare & roast the squash', 'Place an oven rack in the center of the oven, then preheat to 450°F. Wash and dry the fresh produce. Using a sharp, sturdy knife, carefully halve the squash lengthwise; using a spoon, scoop out and discard the pulp and seeds. Place in a baking dish, cut side up. Drizzle with olive oil and season with salt and pepper; arrange cut side down. Fill the dish with 1/4 inch of water. Roast 32 to 35 minutes, or until the cut side of the squash is tender when pierced with a fork. Remove from the oven.', 'images/roasted-squash-curry/step-1.jpg', 'images/roasted-squash-curry/step-1@2x.jpg'),
(24, 2, 'Cook the rice', 'While the squash roasts, in a small saucepan, combine the rice, lime leaf, a big pinch of salt, and 1 cup of water. Heat to boiling on high. Once boiling, cover and reduce the heat to low. Cook 12 to 14 minutes, or until the water has been absorbed and the rice is tender. Turn off the heat. Carefully remove and discard the lime leaf. Fluff the cooked rice with a fork. Cover and set aside in a warm place.', 'images/roasted-squash-curry/step-2.jpg', 'images/roasted-squash-curry/step-2@2x.jpg'),
(24, 3, 'Prepare the remaining ingredients', 'While the rice cooks, peel and thinly slice the onion. Peel and finely chop the ginger. Quarter the lime. Cut off and discard the root end of the bok choy; thinly slice crosswise. Pick the mint leaves off the stems; discard the stems.', 'images/roasted-squash-curry/step-3.jpg', 'images/roasted-squash-curry/step-3@2x.jpg'),
(24, 4, 'Cook the aromatics', 'While the rice continues to cook, in a large pan (nonstick, if you have one), heat 2 teaspoons of olive oil on medium-high until hot. Add the sliced onion; season with salt and pepper. Cook, stirring occasionally, 3 to 4 minutes, or until slightly softened. Add the chopped ginger; season with salt and pepper. Cook, stirring frequently, 1 to 2 minutes, or until lightly browned and fragrant.', 'images/roasted-squash-curry/step-4.jpg', 'images/roasted-squash-curry/step-4@2x.jpg'),
(24, 5, 'Make the curry sauce', 'To the pan, add the coconut milk (shaking the can just before opening), sugar, and as much of the curry paste as you\'d like, depending on how spicy you\'d like the dish to be; season with salt and pepper. Cook, stirring occasionally, 3 to 4 minutes, or until slightly thickened. Turn off the heat and season with salt and pepper to taste.', 'images/roasted-squash-curry/step-5.jpg', 'images/roasted-squash-curry/step-5@2x.jpg'),
(24, 6, 'Finish the curry & serve your dish', 'When cool enough to handle, using a fork, scrape the flesh of the roasted squash into a bowl; separate any clumps. (The result should resemble cooked spaghetti.) Discard the skins. Add the squash and sliced bok choy to the pan of curry. Cook on medium-high, stirring frequently, 2 to 3 minutes, or until thoroughly combined. Turn off the heat. Stir in the juice of 2 lime wedges; season with salt and pepper to taste. Top the cooked rice with the finished curry. Garnish with the mung beans and mint leaves (tearing just before adding). Serve with the remaining lime wedges on the side. Enjoy!', 'images/roasted-squash-curry/step-6.jpg', 'images/roasted-squash-curry/step-6@2x.jpg'),
(25, 1, 'Sear & roast the turkey', 'Remove the honey from the refrigerator to bring to room temperature. Place an oven rack in the center of the oven; preheat to 450°F. Heat a medium pot of salted water to boiling on high. Line a sheet pan with foil. Remove and discard the netting from the turkey; season with salt and pepper on both sides. In a large pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the seasoned turkey, skin side down. Cook 4 to 6 minutes on the first side, or until lightly browned. Flip and cook 3 to 5 minutes, or until lightly browned. Leaving any browned bits (or fond) in the pan on the stove, transfer to the sheet pan, skin side up. Roast 15 to 17 minutes, or until cooked through. (An instant-read thermometer should register 165ºF.) Transfer to a cutting board and let rest for at least 5 minutes.', 'images/roasted-turkey-breast-farro-endive-salad/step-1.jpg', 'images/roasted-turkey-breast-farro-endive-salad/step-1@2x.jpg'),
(25, 2, 'Cook the farro', 'While the turkey roasts, add the farro to the pot of boiling water and cook, uncovered, 17 to 19 minutes, or until tender. Drain thoroughly and return to the pot. Set aside in a warm place.', 'images/roasted-turkey-breast-farro-endive-salad/step-2.jpg', 'images/roasted-turkey-breast-farro-endive-salad/step-2@2x.jpg'),
(25, 3, 'Prepare the ingredients', 'While the farro cooks, wash and dry the fresh produce. Peel and finely chop the shallot. Cut off and discard the root end of the endive; thinly slice crosswise. Quarter and deseed the lemon. Core and small dice the apple. Cut the chives into 1/2-inch pieces.', 'images/roasted-turkey-breast-farro-endive-salad/step-3.jpg', 'images/roasted-turkey-breast-farro-endive-salad/step-3@2x.jpg'),
(25, 4, 'Cook the endive', 'While the farro continues to cook, add 2 teaspoons of olive oil to the pan of reserved fond; heat on medium-high until hot. Add half the chopped shallot; season with salt and pepper. Cook, stirring constantly, 30 seconds to 1 minute, or until softened. Add the sliced endive; season with salt and pepper. Cook, stirring frequently, 1 to 2 minutes, or until softened. Add half the honey (kneading the packet before opening) and the juice of 2 lemon wedges. Cook, stirring constantly, 30 seconds to 1 minute, or until thoroughly combined. Transfer to a bowl and season with salt and pepper to taste. Rinse and wipe out the pan.', 'images/roasted-turkey-breast-farro-endive-salad/step-4.jpg', 'images/roasted-turkey-breast-farro-endive-salad/step-4@2x.jpg'),
(25, 5, 'Make the compote', 'While the farro continues to cook, in the same pan, heat the butter on medium-high until melted. Cook, stirring frequently and swirling the pan, 1 to 2 minutes, or until browned and nuttily fragrant. Add the diced apple and remaining chopped shallot; season with salt and pepper. Cook, stirring frequently, 1 to 2 minutes, or until slightly softened. Add the juice of the remaining lemon wedges and the remaining honey. Cook, stirring constantly, 30 seconds to 1 minute, or until thoroughly combined. Turn off the heat and season with salt and pepper to taste.', 'images/roasted-turkey-breast-farro-endive-salad/step-5.jpg', 'images/roasted-turkey-breast-farro-endive-salad/step-5@2x.jpg'),
(25, 6, 'Make the farro salad & serve your dish', 'Add the cooked endive, mustard, half the sliced chives, and a drizzle of olive oil to the pot of cooked farro. Stir to combine; season with salt and pepper to taste. Thinly slice the rested turkey crosswise. Serve the sliced turkey with the farro salad. Top the turkey with the compote. Garnish with the remaining sliced chives and a drizzle of olive oil. Enjoy!', 'images/roasted-turkey-breast-farro-endive-salad/step-6.jpg', 'images/roasted-turkey-breast-farro-endive-salad/step-6@2x.jpg'),
(26, 1, 'Prepare & cook the potatoes', 'Remove the honey from the refrigerator to bring to room temperature. Wash, dry, and medium dice the potatoes. In a small pot, combine the potatoes, half the saffron, and a big pinch of salt. Add enough water to cover the potatoes by ½ inch. Heat to boiling on high. Once boiling, cook 10 to 12 minutes, or until the potatoes are tender when pierced with a fork. Drain thoroughly and return to the pot. Set aside in a warm place.', 'images/salmon-honey-glazed-carrots/step-1.jpg', 'images/salmon-honey-glazed-carrots/step-1@2x.jpg'),
(26, 2, 'Prepare the remaining ingredients', 'While the potatoes cook, wash and dry the remaining fresh produce. Peel the carrots; cut into ½-inch-thick pieces on an angle. Peel and roughly chop the garlic. Pick the mint leaves off the stems; discard the stems. Using a peeler, remove the rind of the lemon, avoiding the pith; mince to get 2 teaspoons of zest (or use a zester). Quarter and deseed the lemon. In a medium bowl, combine the remaining saffron and the juice of 1 lemon wedge.', 'images/salmon-honey-glazed-carrots/step-2.jpg', 'images/salmon-honey-glazed-carrots/step-2@2x.jpg'),
(26, 3, 'Cook & glaze the carrots', 'In a medium pan (nonstick, if you have one), heat 2 teaspoons of olive oil on medium-high until hot. Add the carrots and garlic; season with salt and pepper. Cook, stirring occasionally, 2 to 3 minutes, or until slightly softened. Add the cumin and honey (kneading the packet before opening). Cook, stirring constantly, 30 seconds to 1 minute, or until fragrant. Add ¾ cup of water. Cook, stirring occasionally, 8 to 10 minutes, or until the carrots are softened and glazed. Transfer to a bowl. Season with salt and pepper to taste.', 'images/salmon-honey-glazed-carrots/step-3.jpg', 'images/salmon-honey-glazed-carrots/step-3@2x.jpg'),
(26, 4, 'Make the yogurt sauce', 'While the carrots cook, to the bowl of saffron-lemon juice mixture, add the yogurt, lemon zest, a drizzle of olive oil, and up to half the Aleppo pepper. Stir to combine; season with salt and pepper to taste.', 'images/salmon-honey-glazed-carrots/step-4.jpg', 'images/salmon-honey-glazed-carrots/step-4@2x.jpg'),
(26, 5, 'Cook the salmon', 'While the carrots continue to cook, pat the salmon fillets dry with paper towels; season with salt and pepper on both sides. Rinse and wipe out the pan used to glaze the carrots. In the same pan, heat 1 tablespoon of olive oil on medium-high until hot. Add the seasoned fillets, skinless side down. Cook 3 to 4 minutes on the first side, or until lightly browned. Flip and cook 2 to 3 minutes, or until lightly browned and cooked to your desired degree of doneness. Turn off the heat.', 'images/salmon-honey-glazed-carrots/step-5.jpg', 'images/salmon-honey-glazed-carrots/step-5@2x.jpg'),
(26, 6, 'Finish & plate your dish', 'While the salmon cooks, add the glazed carrots, the juice of the remaining lemon wedges, half the mint (tearing the leaves just before adding), and as much of the remaining Aleppo pepper as you\'d like to the pot of cooked potatoes. Drizzle with olive oil; stir to combine. Season with salt and pepper to taste. Divide between 2 dishes. Top each with a cooked salmon fillet and a spoonful of the yogurt sauce. Garnish with the remaining mint (tearing the leaves just before adding). Serve with the remaining yogurt sauce on the side. Enjoy!', 'images/salmon-honey-glazed-carrots/step-6.jpg', 'images/salmon-honey-glazed-carrots/step-6@2x.jpg'),
(27, 1, 'Prepare the ingredients', 'Place an oven rack in the center of the oven, then preheat to 450°F. Heat a medium pot of salted water to boiling on high. Wash and dry the fresh produce. Peel the carrots; quarter lengthwise, then halve crosswise. Large dice the potatoes.', 'images/seared-chicken-mashed-potatoes/step-1.jpg', 'images/seared-chicken-mashed-potatoes/step-1@2x.jpg'),
(27, 2, 'Roast & glaze the carrots', 'Place the sliced carrots on a sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer. Roast 15 to 17 minutes, or until lightly browned and tender when pierced with a fork. Carefully transfer to a large bowl. Add half the maple syrup; stir to coat. Season with salt and pepper to taste. Loosely cover with aluminum foil to keep warm.', 'images/seared-chicken-mashed-potatoes/step-2.jpg', 'images/seared-chicken-mashed-potatoes/step-2@2x.jpg'),
(27, 3, 'Cook & mash the potatoes', 'While the carrots roast, add the diced potatoes to the pot of boiling water; cook 14 to 16 minutes, or until tender when pierced with a fork. Turn off the heat. Drain thoroughly and return to the pot. Add the crème fraîche and 1 tablespoon of olive oil. Using a fork, mash to your desired consistency. Season with salt and pepper to taste. Cover to keep warm.', 'images/seared-chicken-mashed-potatoes/step-3.jpg', 'images/seared-chicken-mashed-potatoes/step-3@2x.jpg'),
(27, 4, 'Cook the chicken', 'While the potatoes cook, pat the chicken dry with paper towels; season with salt and pepper on both sides. In a medium pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the seasoned chicken and cook 5 to 7 minutes per side, or until browned and cooked through. Leaving any browned bits (or fond) in the pan, transfer to a cutting board.', 'images/seared-chicken-mashed-potatoes/step-4.jpg', 'images/seared-chicken-mashed-potatoes/step-4@2x.jpg'),
(27, 5, 'Make the pan sauce', 'Add the vinegar and remaining maple syrup to the pan of reserved fond (be careful, as the liquid may splatter). Cook on medium-high, stirring constantly and scraping up any fond, 30 seconds to 1 minute, or until thoroughly combined. Turn off the heat. Stir in the butter until thoroughly combined. Season with salt and pepper to taste.', 'images/seared-chicken-mashed-potatoes/step-5.jpg', 'images/seared-chicken-mashed-potatoes/step-5@2x.jpg'),
(27, 6, 'Slice the chicken & serve your dish', 'Slice the cooked chicken crosswise. Serve the sliced chicken with the mashed potatoes and glazed carrots. Top the chicken with the pan sauce. Enjoy!', 'images/seared-chicken-mashed-potatoes/step-6.jpg', 'images/seared-chicken-mashed-potatoes/step-6@2x.jpg'),
(28, 1, 'Prepare & roast the potatoes', 'Place an oven rack in the center of the oven, then preheat to 450°F. Wash and dry the fresh produce. Cut the potatoes lengthwise into 1/2-inch-thick sticks. Place on a sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer. Roast, flipping halfway through, 22 to 24 minutes, or until lightly browned and tender when pierced with a fork. Remove from the oven.', 'images/seared-steaks-garlic-butter/step-1.jpg', 'images/seared-steaks-garlic-butter/step-1@2x.jpg'),
(28, 2, 'Prepare the remaining ingredients', 'While the potatoes roast, peel and finely chop the garlic. Cut off and discard the root end of the lettuce; roughly chop the leaves. Thinly slice the chives.', 'images/seared-steaks-garlic-butter/step-2.jpg', 'images/seared-steaks-garlic-butter/step-2@2x.jpg'),
(28, 3, 'Make the vinaigrette', 'While the potatoes continue to roast, in a bowl, combine the vinegar and 1/4 of the creamy mustard sauce. Slowly whisk in 2 teaspoons of olive oil until well combined. Season with salt and pepper to taste.', 'images/seared-steaks-garlic-butter/step-3.jpg', 'images/seared-steaks-garlic-butter/step-3@2x.jpg'),
(28, 4, 'Cook the steaks & make the garlic butter', 'While the potatoes continue to roast, pat the steaks dry with paper towels. Season with salt and pepper on both sides. In a large pan, heat 1 tablespoon of olive oil on medium-high until hot. Add the seasoned steaks and cook 4 to 5 minutes on the first side, or until lightly browned. Flip and cook 2 to 3 minutes, or until lightly browned. Add the chopped garlic and butter. Cook, frequently spooning the butter over the steaks, 1 to 2 minutes for medium-rare, or until the steaks are browned and cooked to your desired degree of doneness. Transfer the cooked steaks to a cutting board. Let rest for at least 5 minutes. Transfer the garlic butter to a bowl.', 'images/seared-steaks-garlic-butter/step-4.jpg', 'images/seared-steaks-garlic-butter/step-4@2x.jpg'),
(28, 5, 'Make the salad', 'While the steaks rest, place the chopped lettuce in a large bowl. Add enough of the vinaigrette to coat the lettuce (you may have extra vinaigrette). Toss to coat; season with salt and pepper to taste.', 'images/seared-steaks-garlic-butter/step-5.jpg', 'images/seared-steaks-garlic-butter/step-5@2x.jpg'),
(28, 6, 'Slice the steaks & serve your dish', 'Find the lines of muscle (or grain) on the rested steaks; thinly slice crosswise against the grain. Serve the sliced steaks with the roasted potatoes and salad. Drizzle the steaks and potatoes with the garlic butter. Garnish the salad with the sliced chives. Serve with the remaining creamy mustard sauce on the side. Enjoy!', 'images/seared-steaks-garlic-butter/step-6.jpg', 'images/seared-steaks-garlic-butter/step-6@2x.jpg'),
(29, 1, 'Prepare & roast the sweet potatoes', 'Place an oven rack in the center of the oven, then preheat to 450°F. Wash and dry the sweet potatoes; cut lengthwise into 1-inch wedges. Place on a sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer, skin side down. Roast 22 to 24 minutes, or until browned and tender when pierced with a fork. Remove from the oven.', 'images/shiitake-hoisin-beef-burgers/step-1.jpg', 'images/shiitake-hoisin-beef-burgers/step-1@2x.jpg'),
(29, 2, 'Prepare the remaining ingredients', 'While the sweet potatoes roast, wash and dry the remaining fresh produce. In a bowl, combine the mushrooms and 1 cup of hot water; let stand for at least 10 minutes to rehydrate. Peel and finely chop the garlic; using the flat side of your knife, smash until it resembles a paste (or use a zester). Cut off and discard the root ends of the scallions; thinly slice, separating the white bottoms and green tops. Cut off and discard the root end of the bok choy; thinly slice. Place in a bowl. Drizzle with olive oil and season with salt and pepper; toss to coat. Halve the buns. In a bowl, combine the miso paste and mayonnaise; season with salt and pepper to taste.', 'images/shiitake-hoisin-beef-burgers/step-2.jpg', 'images/shiitake-hoisin-beef-burgers/step-2@2x.jpg'),
(29, 3, 'Form the patties', 'While the sweet potatoes continue to roast, drain the rehydrated mushrooms. Transfer to a cutting board; finely chop. In a large bowl, combine the chopped mushrooms, ground beef, garlic paste, sliced white bottoms of the scallions, and hoisin sauce; season with salt and pepper. Gently mix to combine. Using your hands, form into four ½-inch-thick patties. Transfer to a plate.', 'images/shiitake-hoisin-beef-burgers/step-3.jpg', 'images/shiitake-hoisin-beef-burgers/step-3@2x.jpg'),
(29, 4, 'Cook the patties', 'While the sweet potatoes continue to roast, in a large pan (nonstick, if you have one), heat 2 teaspoons of olive oil on medium-high until hot. Add the patties and cook 3 to 4 minutes per side, or until browned and cooked to your desired degree of doneness. Leaving any browned bits (or fond) in the pan, transfer to a plate.', 'images/shiitake-hoisin-beef-burgers/step-4.jpg', 'images/shiitake-hoisin-beef-burgers/step-4@2x.jpg'),
(29, 5, 'Toast the buns', 'Working in batches if necessary, add the buns, cut side down, to the pan of reserved fond. (If the pan seems dry, add a drizzle of olive oil.) Toast on medium-high 30 seconds to 1 minute, or until lightly browned. Transfer to a work surface.', 'images/shiitake-hoisin-beef-burgers/step-5.jpg', 'images/shiitake-hoisin-beef-burgers/step-5@2x.jpg'),
(29, 6, 'Assemble the burgers & serve your dish', 'Divide the miso mayonnaise, cooked patties, and seasoned bok choy among the toasted buns. Serve the burgers with the roasted sweet potatoes. Garnish the sweet potatoes with the sliced green tops of the scallions. Enjoy!', 'images/shiitake-hoisin-beef-burgers/step-6.jpg', 'images/shiitake-hoisin-beef-burgers/step-6@2x.jpg'),
(30, 1, 'Prepare the ingredients', 'Fill a medium pot with water; add a big pinch of salt and heat to boiling on high. Wash and dry the fresh produce. Cut out and discard the core of the cabbage; thinly slice the leaves. Peel and roughly chop the garlic.', 'images/shrimp-fra-diavolo/step-1.jpg', 'images/shrimp-fra-diavolo/step-1@2x.jpg'),
(30, 2, 'Cook the shrimp', 'Pat the shrimp dry with paper towels; season with salt and pepper. In a medium pan, heat a drizzle of olive oil on medium-high until hot. Add the seasoned shrimp; cook, stirring occasionally, 3 to 4 minutes, or until opaque and cooked through. Leaving any browned bits (or fond) in the pan, transfer to a plate. Set aside in a warm place.', 'images/shrimp-fra-diavolo/step-2.jpg', 'images/shrimp-fra-diavolo/step-2@2x.jpg'),
(30, 3, 'Cook the cabbage', 'Add the sliced cabbage to the pan of reserved fond; season with salt and pepper. (If the pan seems dry, add a drizzle of olive oil.) Cook on medium-high, stirring occasionally, 2 to 3 minutes, or until slightly softened. Add the verjus and 1/4 cup of water; season with salt and pepper. Cook, stirring occasionally and scraping up any fond, 3 to 5 minutes, or until the cabbage has softened and the water has cooked off. Transfer to the plate of cooked shrimp. Wipe out the pan.', 'images/shrimp-fra-diavolo/step-3.jpg', 'images/shrimp-fra-diavolo/step-3@2x.jpg'),
(30, 4, 'Cook the pasta', 'While the cabbage cooks, add the pasta to the pot of boiling water. Cook, stirring occasionally, 9 to 11 minutes, or until al dente (still slightly firm to the bite). Reserving 1/2 cup of the pasta cooking water, drain thoroughly.', 'images/shrimp-fra-diavolo/step-4.jpg', 'images/shrimp-fra-diavolo/step-4@2x.jpg'),
(30, 5, 'Make the sauce', 'While the pasta cooks, in the same pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the chopped garlic; season with salt and pepper. Cook, stirring constantly, 30 seconds to 1 minute, or until softened and fragrant. Add the tomato sauce, 1/3 cup of water, and as much of the chile paste as you\'d like, depending on how spicy you\'d like the dish to be; season with salt and pepper. Cook, stirring occasionally, 4 to 5 minutes, or until thickened. Season with salt and pepper to taste.', 'images/shrimp-fra-diavolo/step-5.jpg', 'images/shrimp-fra-diavolo/step-5@2x.jpg'),
(30, 6, 'Finish & serve your dish', 'Add the cooked pasta, cooked shrimp and cabbage, and half the reserved pasta cooking water to the pan. Cook, stirring vigorously, 1 to 2 minutes, or until coated. (If the sauce seems dry, gradually add the remaining pasta cooking water to achieve your desired consistency.) Turn off the heat; stir in the crème fraîche until thoroughly combined. Season with salt and pepper to taste. Top the finished pasta with the almonds and a drizzle of olive oil. Enjoy!', 'images/shrimp-fra-diavolo/step-6.jpg', 'images/shrimp-fra-diavolo/step-6@2x.jpg'),
(31, 1, 'Prepare the ingredients', 'Remove the dough and honey from the refrigerator to bring to room temperature. Place an oven rack in the center of the oven, then preheat to 475°F. Wash and dry the fresh produce. Thinly slice the mushrooms. Peel and roughly chop the garlic. Peel and thinly slice the onion. Remove and discard the stems of the kale; roughly chop the leaves. Grate both cheeses on the large side of a box grater (discarding any rind). Combine in a bowl.', 'images/smoked-gouda-mushroom-flatbread/step-1.jpg', 'images/smoked-gouda-mushroom-flatbread/step-1@2x.jpg'),
(31, 2, 'Start the vegetables', 'In a large pan (nonstick, if you have one), heat a drizzle of olive oil on medium-high until hot. Add the sliced mushrooms in an even layer. Cook, without stirring, 2 to 3 minutes, or until lightly browned. Add the chopped garlic and sliced onion; season with salt and pepper. Cook, stirring occasionally, 2 to 3 minutes, or until lightly browned and fragrant.', 'images/smoked-gouda-mushroom-flatbread/step-2.jpg', 'images/smoked-gouda-mushroom-flatbread/step-2@2x.jpg'),
(31, 3, 'Finish the vegetables', 'Add the chopped kale to the pan; season with salt and pepper. Cook, stirring frequently, 1 to 2 minutes, or until slightly wilted. Add 1/4 cup of water; season with salt and pepper. Cook, stirring occasionally, 3 to 4 minutes, or until the kale has wilted and the water has cooked off. Turn off the heat. Season with salt and pepper to taste.', 'images/smoked-gouda-mushroom-flatbread/step-3.jpg', 'images/smoked-gouda-mushroom-flatbread/step-3@2x.jpg'),
(31, 4, 'Assemble & bake the flatbread', 'Lightly oil a sheet pan. On a work surface, using your hands and a rolling pin (or a wine bottle), gently stretch and roll the dough to a 1/8-inch thickness. (If the dough is resistant, let rest for 5 minutes.) Carefully transfer the dough to the sheet pan; rub the dough into the pan to coat the bottom in oil. Leaving a 1-inch border around the edges, evenly top the prepared dough with the finished vegetables, grated cheeses, and a drizzle of olive oil. Season with salt and pepper. Bake, rotating the sheet pan halfway through, 14 to 16 minutes, or until the crust has browned and the cheese has melted. Remove from the oven and let stand for at least 2 minutes.', 'images/smoked-gouda-mushroom-flatbread/step-4.jpg', 'images/smoked-gouda-mushroom-flatbread/step-4@2x.jpg'),
(31, 5, 'Prepare the remaining ingredients', 'While the flatbread bakes, cut off and discard the root end of the endive; roughly chop the leaves. Core, quarter, and thinly slice the apple. To make the dressing, in a large bowl, whisk together the vinegar, honey (kneading the packet before opening), and 1 tablespoon of olive oil until thoroughly combined. Season with salt and pepper to taste.', 'images/smoked-gouda-mushroom-flatbread/step-5.jpg', 'images/smoked-gouda-mushroom-flatbread/step-5@2x.jpg'),
(31, 6, 'Make the salad & serve your dish', 'Just before serving, add the chopped endive and sliced apple to the bowl of dressing. Toss to combine; season with salt and pepper to taste. Serve the baked flatbread with the salad on the side. Enjoy!', 'images/smoked-gouda-mushroom-flatbread/step-6.jpg', 'images/smoked-gouda-mushroom-flatbread/step-6@2x.jpg'),
(32, 1, 'Prepare & cook the beet', 'Heat a small pot of salted water to boiling on high. Wash and dry the fresh produce. Peel the beet and cut lengthwise into 1/4-inch wedges. Once the pot of water is boiling, add the beet wedges and cook, uncovered, 22 to 24 minutes, or until tender when pierced with a fork. Drain and rinse under cold water for 30 seconds to 1 minute to stop the cooking process. Pat dry with paper towels and transfer to a large bowl.', 'images/spicy-chicken-quesadillas/step-1.jpg', 'images/spicy-chicken-quesadillas/step-1@2x.jpg'),
(32, 2, 'Prepare the remaining ingredients', 'While the beet cooks, cut off and discard the root ends of the scallions; thinly slice, separating the white bottoms and green tops. Using a peeler, remove the green rind of the lime, avoiding the white pith; mince to get 2 teaspoons of zest (or use a zester). Quarter the lime. Grate the cheese on the large side of a box grater. Peel the orange; halve lengthwise, then thinly slice crosswise. To make the lime crema, in a bowl, combine the crema and the juice of 2 lime wedges; season with salt and pepper to taste. Cut out and discard the stem, ribs, and seeds of the pepper; finely chop. Thoroughly wash your hands, knife, and cutting board immediately after handling the pepper.', 'images/spicy-chicken-quesadillas/step-2.jpg', 'images/spicy-chicken-quesadillas/step-2@2x.jpg'),
(32, 3, 'Cook & chop the chicken', 'While the beet continues to cook, pat the chicken dry with paper towels; season on both sides with salt, pepper, and the spice blend. In a large pan (nonstick, if you have one), heat 2 teaspoons of olive oil on medium-high until hot. Add the seasoned chicken; cook 3 to 4 minutes per side, or until browned and cooked through. Transfer to a cutting board; when cool enough to handle, roughly chop. Transfer to a medium bowl. Rinse and wipe out the pan.', 'images/spicy-chicken-quesadillas/step-3.jpg', 'images/spicy-chicken-quesadillas/step-3@2x.jpg'),
(32, 4, 'Make the filling & assemble the quesadillas', 'To the bowl of chopped chicken, add the sliced white bottoms of the scallions, lime zest, the juice of 1 lime wedge, a drizzle of olive oil, and as much of the chopped pepper as you\'d like, depending on how spicy you\'d like the dish to be. Stir to combine; season with salt and pepper to taste. Place the tortillas on a work surface. Sprinkle the grated cheese onto 1 side of each tortilla. Evenly top with the filling. Fold each tortilla in half over the filling.', 'images/spicy-chicken-quesadillas/step-4.jpg', 'images/spicy-chicken-quesadillas/step-4@2x.jpg'),
(32, 5, 'Cook the quesadillas', 'In the same pan, heat 2 teaspoons of olive oil on medium until hot. Add the quesadillas; cook 2 to 3 minutes per side, or until the tortillas are browned and the cheese has melted. (If the pan seems dry, add a drizzle of olive oil before flipping.) Transfer to a cutting board; immediately season with salt and pepper.', 'images/spicy-chicken-quesadillas/step-5.jpg', 'images/spicy-chicken-quesadillas/step-5@2x.jpg'),
(32, 6, 'Make the salad & serve your dish', 'While the quesadillas cook, add the sliced orange, peanuts, the juice of the remaining lime wedge, and a drizzle of olive oil to the bowl of cooked beet. Stir to combine; season with salt and pepper to taste. Cut the cooked quesadillas in half. Garnish the quesadillas and salad with the sliced green tops of the scallions. Serve with the lime crema on the side. Enjoy!', 'images/spicy-chicken-quesadillas/step-6.jpg', 'images/spicy-chicken-quesadillas/step-6@2x.jpg'),
(33, 1, 'Prepare the ingredients', 'Heat a large pot of salted water to boiling on high. Wash and dry the fresh produce. Peel and finely chop the ginger. Peel and roughly chop the garlic. Cut off and discard the root end of the bok choy; roughly chop the leaves and stems, keeping them separate. Thinly slice the chives.', 'images/spicy-pork-korean-rice-cakes/step-1.jpg', 'images/spicy-pork-korean-rice-cakes/step-1@2x.jpg'),
(33, 2, 'Cook the pork', 'In a large pan, heat 2 teaspoons of olive oil on medium until hot. Add the ground pork (removing and discarding the paper lining from the bottom); season with salt and pepper. Cook, frequently breaking the meat apart with a spoon, 4 to 6 minutes, or until lightly browned.', 'images/spicy-pork-korean-rice-cakes/step-2.jpg', 'images/spicy-pork-korean-rice-cakes/step-2@2x.jpg'),
(33, 3, 'Add the aromatics', 'Add the chopped ginger and garlic to the pan; season with salt and pepper. Cook, stirring occasionally, 2 to 3 minutes, or until softened and the pork is cooked through.', 'images/spicy-pork-korean-rice-cakes/step-3.jpg', 'images/spicy-pork-korean-rice-cakes/step-3@2x.jpg'),
(33, 4, 'Make the sauce', 'To the pan, add the chopped bok choy stems, soy glaze, black bean sauce, ½ cup of water, and as much of the gochujang as you\'d like, depending on how spicy you\'d like the dish to be. Cook, stirring occasionally, 3 to 4 minutes, or until the bok choy stems have softened and the liquid has thickened. Turn off the heat. Season with salt and pepper to taste.', 'images/spicy-pork-korean-rice-cakes/step-4.jpg', 'images/spicy-pork-korean-rice-cakes/step-4@2x.jpg'),
(33, 5, 'Cook the rice cakes', 'While the sauce cooks, add the rice cakes to the pot of boiling water and cook 2 to 3 minutes, or until tender. Drain thoroughly.', 'images/spicy-pork-korean-rice-cakes/step-5.jpg', 'images/spicy-pork-korean-rice-cakes/step-5@2x.jpg'),
(33, 6, 'Finish & serve your dish', 'Add the cooked rice cakes and chopped bok choy leaves to the pan of cooked pork and sauce; season with salt and pepper. Cook on medium-high, stirring frequently, 1 to 2 minutes, or until the rice cakes are thoroughly coated and the bok choy leaves are slightly wilted. Turn off the heat; stir in the crème fraîche and half the sliced chives. Season with salt and pepper to taste. Garnish the finished pork and rice cakes with the remaining sliced chives. Enjoy!', 'images/spicy-pork-korean-rice-cakes/step-6.jpg', 'images/spicy-pork-korean-rice-cakes/step-6@2x.jpg'),
(34, 1, 'Prepare the ingredients & marinate the radish', 'Wash and dry the fresh produce. Peel the carrots; thinly slice on an angle. Slice the celery on an angle into 1/2-inch-thick pieces. Halve the orange; squeeze the juice into a medium bowl, straining out any seeds. Peel and roughly chop the garlic. Peel and finely chop the ginger. Cut off and discard the root end of the bok choy; roughly chop. Quarter and deseed the lemon. Cut off and discard the ends of the radishes; small dice. Place in a bowl and top with the juice of 1 lemon wedge and half the sesame oil. Season with salt and pepper. Set aside to marinate, stirring occasionally, for at least 10 minutes. Season with salt and pepper to taste.', 'images/sweet-sour-vegetable-stir-fry/step-1.jpg', 'images/sweet-sour-vegetable-stir-fry/step-1@2x.jpg'),
(34, 2, 'Cook the rice', 'While the radishes marinate, in a medium saucepan, combine the rice, a big pinch of salt, and 1 1/2 cups of water; heat to boiling on high. Once boiling, cover and reduce the heat to low. Cook 12 to 14 minutes, or until the water has been absorbed and the rice is tender. Turn off the heat and fluff with a fork. Cover to keep warm.', 'images/sweet-sour-vegetable-stir-fry/step-2.jpg', 'images/sweet-sour-vegetable-stir-fry/step-2@2x.jpg'),
(34, 3, 'Start the stir-fry', 'While the rice cooks, in a large pan (nonstick, if you have one), heat 2 teaspoons of olive oil on medium-high until hot. Add the sliced carrots and celery; season with salt and pepper. Cook, stirring occasionally, 6 to 7 minutes, or until slightly softened.', 'images/sweet-sour-vegetable-stir-fry/step-3.jpg', 'images/sweet-sour-vegetable-stir-fry/step-3@2x.jpg'),
(34, 4, 'Make the sauce', 'While the vegetables cook, to the bowl of orange juice, add the soy glaze, soy marinade, and the juice of the remaining lemon wedges. Stir to combine; season with salt and pepper to taste.', 'images/sweet-sour-vegetable-stir-fry/step-4.jpg', 'images/sweet-sour-vegetable-stir-fry/step-4@2x.jpg'),
(34, 5, 'Finish the stir-fry', 'To the pan of vegetables, add the chopped garlic and ginger and remaining sesame oil. Cook, stirring constantly, 30 seconds to 1 minute, or until fragrant. Add the sauce and chopped bok choy; cook, stirring constantly, 1 to 2 minutes, or until the bok choy leaves have wilted. Transfer to a bowl and season with salt and pepper to taste. Rinse and wipe out the pan.', 'images/sweet-sour-vegetable-stir-fry/step-5.jpg', 'images/sweet-sour-vegetable-stir-fry/step-5@2x.jpg'),
(34, 6, 'Fry the eggs & serve your dish', 'In the same pan, heat 2 teaspoons of olive oil on medium-high until hot. Keeping them separate, crack the eggs into the pan; season with salt and pepper. Cook 4 to 5 minutes, or until the whites are set and the yolks are cooked to your desired degree of doneness. Turn off the heat. Stir the marinated radishes (including any marinating liquid) into the saucepan of cooked rice. Serve the finished rice with the finished stir-fry. Top with the fried eggs and peanuts. Enjoy!', 'images/sweet-sour-vegetable-stir-fry/step-6.jpg', 'images/sweet-sour-vegetable-stir-fry/step-6@2x.jpg'),
(35, 1, 'Prepare the ingredients & rehydrate the mushrooms', 'Wash and dry the fresh produce. In a bowl, combine the mushrooms and 1 cup of warm water. Let stand for at least 10 minutes. Peel the carrots; thinly slice into rounds. Cut off and discard the root end of the bok choy; thinly slice the stems and roughly chop the leaves, keeping them separate. Quarter the lime.', 'images/thai-curry-chicken/step-1.jpg', 'images/thai-curry-chicken/step-1@2x.jpg'),
(35, 2, 'Cook the rice', 'In a small saucepan, combine the rice, a big pinch of salt, and 1 1/2 cups of water; heat to boiling on high. Once boiling, cover and reduce the heat to low. Cook 12 to 14 minutes, or until the water has been absorbed and the rice is tender. Turn off the heat and fluff with a fork. Cover and set aside in a warm place.', 'images/thai-curry-chicken/step-2.jpg', 'images/thai-curry-chicken/step-2@2x.jpg'),
(35, 3, 'Brown the chicken', 'While the rice cooks, pat the chicken dry with paper towels; season with salt and pepper. In a large pan, heat 1 tablespoon of olive oil on medium-high until hot. Add the seasoned chicken; cook, stirring occasionally, 3 to 4 minutes, or until lightly browned. Leaving any browned bits (or fond) in the pan, transfer to a plate.', 'images/thai-curry-chicken/step-3.jpg', 'images/thai-curry-chicken/step-3@2x.jpg'),
(35, 4, 'Chop the mushrooms & start the curry', 'While the chicken browns, drain the rehydrated mushrooms. Transfer to a cutting board and roughly chop. Add 2 teaspoons of olive oil to the pan of reserved fond; heat on medium-high until hot. Add the sliced carrots and as much of the curry paste as you\'d like, depending on how spicy you\'d like the dish to be; season with salt and pepper. Cook, stirring frequently, 1 to 2 minutes, or until slightly softened and fragrant.', 'images/thai-curry-chicken/step-4.jpg', 'images/thai-curry-chicken/step-4@2x.jpg'),
(35, 5, 'Finish the curry & serve your dish', 'To the pan, add the browned chicken, sliced bok choy stems, Golden Mountain sauce, chopped mushrooms, and coconut milk (shaking the can just before opening); season with salt and pepper. Heat to boiling on high. Once boiling, reduce the heat to medium-high and cook, stirring occasionally, 4 to 5 minutes, or until the liquid is slightly reduced in volume. Add the chopped bok choy leaves. Cook, stirring occasionally, 2 to 3 minutes, or until the liquid is slightly thickened and the chicken is cooked through. Turn off the heat and stir in the juice of 2 lime wedges. Season with salt and pepper to taste. Serve the finished curry and cooked rice with the remaining lime wedges on the side. Enjoy!', 'images/thai-curry-chicken/step-5.jpg', 'images/thai-curry-chicken/step-5@2x.jpg'),
(36, 1, 'Cook the lentils', 'Place an oven rack in the center of the oven, then preheat to 450°F. Heat a medium saucepan of salted water to boiling on high. Once boiling, add the lentils and cook, uncovered, 24 to 26 minutes, or until tender. Turn off the heat. Drain thoroughly and rinse under warm water; return to the pot. Cover to keep warm.', 'images/tilapia-black-lentil-salad/step-1.jpg', 'images/tilapia-black-lentil-salad/step-1@2x.jpg'),
(36, 2, 'Prepare & roast the broccoli', 'While the lentils cook, wash and dry the fresh produce. Cut off and discard the bottom 1/2 inch of the broccoli stem; cut the broccoli into small pieces, keeping the florets intact. Place on a sheet pan. Drizzle with olive oil and season with salt and pepper; toss to coat. Arrange in an even layer. Roast 15 to 17 minutes, or until browned and tender when pierced with a fork. Remove from the oven.', 'images/tilapia-black-lentil-salad/step-2.jpg', 'images/tilapia-black-lentil-salad/step-2@2x.jpg'),
(36, 3, 'Prepare the remaining ingredients', 'While the broccoli roasts, peel the garlic. Roughly chop 1 clove. Finely chop the remaining clove; using the flat side of your knife, smash until it resembles a paste (or use a zester). Using a peeler, remove the yellow rind of the lemon, avoiding the white pith; mince the rind to get 2 teaspoons of zest (or use a zester). Quarter and deseed the lemon. Roughly chop the peppers. Finely chop the parsley leaves and stems. To make the gremolata, in a bowl, combine the lemon zest, chopped peppers, half the chopped parsley, the juice of 2 lemon wedges, 1 tablespoon of olive oil, and as much of the garlic paste as you\'d like. Season with salt and pepper to taste.', 'images/tilapia-black-lentil-salad/step-3.jpg', 'images/tilapia-black-lentil-salad/step-3@2x.jpg'),
(36, 4, 'Cook the fish', 'Pat the fish fillets dry with paper towels; season with salt and pepper on both sides. In a large pan (nonstick, if you have one), heat 2 teaspoons of olive oil on medium-high until hot. Add the seasoned fillets and cook 2 to 3 minutes per side, or until lightly browned and cooked through. Leaving any browned bits (or fond) in the pan, transfer to a plate.', 'images/tilapia-black-lentil-salad/step-4.jpg', 'images/tilapia-black-lentil-salad/step-4@2x.jpg'),
(36, 5, 'Make the pan sauce', 'Add the capers, chopped garlic, butter, and 1 tablespoon of olive oil to the pan of reserved fond; season with salt and pepper. Cook on medium-high, stirring constantly and scraping up any fond, 1 to 2 minutes, or until browned and fragrant. Turn off the heat; stir in the juice of the remaining lemon wedges (be careful, as the liquid may splatter). Season with salt and pepper to taste.', 'images/tilapia-black-lentil-salad/step-5.jpg', 'images/tilapia-black-lentil-salad/step-5@2x.jpg'),
(36, 6, 'Finish the lentils & serve your dish', 'To the saucepan of cooked lentils, add the roasted broccoli and gremolata. Stir to combine; season with salt and pepper to taste. Serve the finished lentils with the cooked fish fillets. Top the fish with the pan sauce. Garnish with the remaining chopped parsley. Enjoy!', 'images/tilapia-black-lentil-salad/step-6.jpg', 'images/tilapia-black-lentil-salad/step-6@2x.jpg'),
(37, 1, 'Prepare the ingredients', 'Wash and dry the fresh produce. Cut off and discard the root end of the lettuce; separate 8 large leaves. Peel and thinly slice the red onion. Thinly slice the mushrooms. Peel the carrot and grate on the large side of a box grater. Cut off and discard the ends of the radishes; thinly slice into rounds. Peel and finely chop the garlic and ginger. Thinly slice the scallions. Quarter the lime. Peel the orange; cut into bite-sized pieces.', 'images/togarashi-chicken-lettuce-cups/step-1.jpg', 'images/togarashi-chicken-lettuce-cups/step-1@2x.jpg'),
(37, 2, 'Cook the vegetables', 'In a large pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the sliced onion and mushrooms; season with salt and pepper. Cook, stirring occasionally, 4 to 6 minutes, or until softened and browned. Transfer to a large bowl.', 'images/togarashi-chicken-lettuce-cups/step-2.jpg', 'images/togarashi-chicken-lettuce-cups/step-2@2x.jpg'),
(37, 3, 'Cook the chicken', 'In the same pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the ground chicken, chopped garlic and ginger, and the togarashi seasoning; season with salt and pepper. Cook, frequently breaking the meat apart with a spoon, 4 to 6 minutes, or until browned and cooked through. Add the coconut aminos and vinegar; cook, stirring, 1 minute, or until coated. Turn off the heat.', 'images/togarashi-chicken-lettuce-cups/step-3.jpg', 'images/togarashi-chicken-lettuce-cups/step-3@2x.jpg'),
(37, 4, 'Make the filling', 'Add the cooked chicken, grated carrot, sliced radishes, half the scallions, and the juice of 2 lime wedges to the bowl of cooked vegetables. Stir to combine; season with salt and pepper to taste.', 'images/togarashi-chicken-lettuce-cups/step-4.jpg', 'images/togarashi-chicken-lettuce-cups/step-4@2x.jpg'),
(37, 5, 'Assemble the lettuce cups & serve your dish', 'Divide the filling among the lettuce leaves. Top with the orange pieces, the cashews, and the remaining scallions. Serve with the remaining lime wedges on the side. Enjoy!', 'images/togarashi-chicken-lettuce-cups/step-5.jpg', 'images/togarashi-chicken-lettuce-cups/step-5@2x.jpg'),
(38, 1, 'Marinate the steaks', 'Wash and dry the fresh produce. Peel and finely chop the ginger and garlic. In a large bowl, whisk together the ponzu sauce, soy sauce, sugar, half the chopped ginger, and half the chopped garlic. Pat the steaks dry with paper towels and add to the bowl; turn to coat. Set aside to marinate for at least 10 minutes, turning occasionally.', 'images/top-chef-ginger-marinated-grassfed-steaks/step-1.jpg', 'images/top-chef-ginger-marinated-grassfed-steaks/step-1@2x.jpg'),
(38, 2, 'Cook the rice', 'While the steaks marinate, in a medium pot, combine the rice, a big pinch of salt, and 1 1/2 cups of water; heat to boiling on high. Once boiling, cover and reduce the heat to low. Cook 12 to 14 minutes, or until the water has been absorbed and the rice is tender. Turn off the heat and fluff with a fork. Cover to keep warm.', 'images/top-chef-ginger-marinated-grassfed-steaks/step-2.jpg', 'images/top-chef-ginger-marinated-grassfed-steaks/step-2@2x.jpg'),
(38, 3, 'Prepare the vegetables', 'While the rice cooks, peel the carrots; thinly slice on an angle. Snap off and discard the stem ends of the snow peas; remove the strings. Cut off and discard the root end of the bok choy; roughly chop. Cut off and discard the root ends of the scallions; thinly slice, separating the white bottoms and green tops.', 'images/top-chef-ginger-marinated-grassfed-steaks/step-3.jpg', 'images/top-chef-ginger-marinated-grassfed-steaks/step-3@2x.jpg'),
(38, 4, 'Cook the steaks', 'Reserving the marinade, transfer the steaks to a plate; season with salt and pepper on both sides. In a large pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the steaks and cook 4 to 5 minutes per side for medium-rare, or until browned and cooked to your desired degree of doneness. Transfer to a cutting board and let rest for at least 5 minutes. Wipe out the pan.', 'images/top-chef-ginger-marinated-grassfed-steaks/step-4.jpg', 'images/top-chef-ginger-marinated-grassfed-steaks/step-4@2x.jpg'),
(38, 5, 'Stir-fry the vegetables', 'In the same pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the sliced carrots and white bottoms of the scallions; season with salt and pepper. Cook, stirring frequently, 2 to 3 minutes, or until slightly softened. Add the snow peas, chopped bok choy, and the remaining ginger and garlic. Cook, stirring frequently, 2 to 3 minutes, or until the vegetables are tender-crisp. Transfer to a bowl; season with salt and pepper to taste.', 'images/top-chef-ginger-marinated-grassfed-steaks/step-5.jpg', 'images/top-chef-ginger-marinated-grassfed-steaks/step-5@2x.jpg'),
(38, 6, 'Make the pan sauce & serve your dish', 'Add the reserved marinade and 2 tablespoons of water to the same pan. Cook on medium-high, stirring frequently, 1 to 2 minutes, or until slightly reduced. Turn off the heat and stir in the butter until melted. Thinly slice the rested steaks against the grain. Serve the sliced steaks with the cooked rice and stir-fried vegetables. Top the steaks and rice with the pan sauce. Garnish with the sliced green tops of the scallions. Enjoy!', 'images/top-chef-ginger-marinated-grassfed-steaks/step-6.jpg', 'images/top-chef-ginger-marinated-grassfed-steaks/step-6@2x.jpg'),
(39, 1, 'Prepare the ingredients & make the glaze', 'Wash and dry the fresh produce. Quarter the mushrooms. Peel and thinly slice the shallot. Peel and finely chop the ginger. Cut off and discard the root end of the bok choy; roughly chop. Quarter the lime. Cut off and discard the ends of the radishes; thinly slice into rounds. Place in a bowl and top with the juice of 1 lime wedge and a drizzle of olive oil; season with salt and pepper. Stir to coat. In a bowl, combine the ponzu sauce, sweet chili sauce, sugar, 1/4 cup of water, and as much of the soy marinade as you\'d like.', 'images/top-chef-seared-grassfed-steaks/step-1.jpg', 'images/top-chef-seared-grassfed-steaks/step-1@2x.jpg'),
(39, 2, 'Cook the rice', 'In a medium pot, combine the rice, a big pinch of salt, and 1 1/2 cups of water; heat to boiling on high. Once boiling, cover and reduce the heat to low. Cook 12 to 14 minutes, or until the water has been absorbed and the rice is tender. Turn off the heat and fluff with a fork. Cover to keep warm.', 'images/top-chef-seared-grassfed-steaks/step-2.jpg', 'images/top-chef-seared-grassfed-steaks/step-2@2x.jpg'),
(39, 3, 'Cook the steaks', 'While the rice cooks, pat the steaks dry with paper towels; season with salt and pepper on both sides. In a large pan, heat 2 tablespoons of olive oil on medium-high until hot. Add the seasoned steaks and cook 4 to 5 minutes per side for medium-rare, or until browned and cooked to your desired degree of doneness. Leaving any browned bits (or fond) in the pan, transfer to a cutting board and let rest for at least 5 minutes.', 'images/top-chef-seared-grassfed-steaks/step-3.jpg', 'images/top-chef-seared-grassfed-steaks/step-3@2x.jpg'),
(39, 4, 'Cook the vegetables', 'While the steaks rest, add 1 tablespoon of olive oil to the pan of reserved fond; heat on medium-high until hot. Add the quartered mushrooms in an even layer. Cook, without stirring, 3 to 4 minutes, or until lightly browned and slightly softened. Add the sliced shallot and chopped ginger; season with salt and pepper. Cook, stirring constantly, 30 seconds to 1 minute, or until fragrant.', 'images/top-chef-seared-grassfed-steaks/step-4.jpg', 'images/top-chef-seared-grassfed-steaks/step-4@2x.jpg'),
(39, 5, 'Glaze the vegetables', 'Add the glaze and chopped bok choy to the pan; season with salt and pepper. Cook, stirring occasionally, 4 to 5 minutes, or until the glaze is slightly thickened and the vegetables have softened. Turn off the heat and stir in the juice of the remaining lime wedges. Season with salt and pepper to taste.', 'images/top-chef-seared-grassfed-steaks/step-5.jpg', 'images/top-chef-seared-grassfed-steaks/step-5@2x.jpg'),
(39, 6, 'Slice the steaks & serve your dish', 'Find the lines of muscle (or grain) on the rested steaks; thinly slice crosswise against the grain. Serve the sliced steaks with the cooked rice and glazed vegetables. Garnish with the marinated radishes (draining before adding). Enjoy!', 'images/top-chef-seared-grassfed-steaks/step-6.jpg', 'images/top-chef-seared-grassfed-steaks/step-6@2x.jpg'),
(40, 1, 'Cook the lentils', 'Heat a medium pot of salted water to boiling on high. Once boiling, add the lentils and cook, uncovered, 27 to 29 minutes, or until tender. Drain thoroughly and rinse under warm water 30 seconds to 1 minute, or until the water runs clear.', 'images/tuscan-chicken-green-lentil-stew/step-1.jpg', 'images/tuscan-chicken-green-lentil-stew/step-1@2x.jpg'),
(40, 2, 'Prepare the ingredients', 'While the lentils cook, wash and dry the fresh produce. Peel and thinly slice the onion. Peel and roughly chop the garlic. Peel and medium dice the carrots. Roughly chop the capers. Remove and discard the stems of the collard greens; roughly chop the leaves.', 'images/tuscan-chicken-green-lentil-stew/step-2.jpg', 'images/tuscan-chicken-green-lentil-stew/step-2@2x.jpg'),
(40, 3, 'Cook the chicken', 'While the lentils continue to cook, pat the chicken dry with paper towels; season on both sides with salt, pepper, and half the spice blend. In a large pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the seasoned chicken and cook 5 to 7 minutes per side, or until browned and cooked through. Leaving any browned bits (or fond) in the pan, transfer to a cutting board.', 'images/tuscan-chicken-green-lentil-stew/step-3.jpg', 'images/tuscan-chicken-green-lentil-stew/step-3@2x.jpg'),
(40, 4, 'Cook the vegetables', 'Add the sliced onion, chopped garlic, and diced carrots to pan of reserved fond; season with salt and pepper. (If the pan seems dry, add 2 teaspoons of olive oil.) Cook on medium-high, stirring frequently, 4 to 5 minutes, or until softened and fragrant. Add the tomato paste, chopped capers, remaining spice blend, and as much of the red pepper flakes as you\'d like, depending on how spicy you\'d like the dish to be. Cook, stirring constantly, 30 seconds to 1 minute, or until dark red and fragrant. Add the chopped collard greens and 2 cups of water; season with salt and pepper. Cook, stirring occasionally and scraping up any fond, 8 to 9 minutes, or until the collard greens have wilted and the liquid has thickened. Turn off the heat.', 'images/tuscan-chicken-green-lentil-stew/step-4.jpg', 'images/tuscan-chicken-green-lentil-stew/step-4@2x.jpg'),
(40, 5, 'Warm the chicken in the stew', 'Return the cooked chicken (and any juices from the cutting board) to the pan of cooked vegetables, nestling it into the stew. Cook on medium, covered, 2 to 3 minutes, or until the chicken is warmed through. Transfer the chicken back to the cutting board.', NULL, NULL),
(40, 6, 'Slice the chicken & serve your dish', 'Slice the cooked chicken crosswise. Add the cooked lentils and vinegar to the pan of cooked vegetables. Stir to combine. Season with salt and pepper to taste. Serve the finished lentils and vegetables topped with the sliced chicken. Garnish with the cheese. Enjoy!', 'images/tuscan-chicken-green-lentil-stew/step-6.jpg', 'images/tuscan-chicken-green-lentil-stew/step-6@2x.jpg');

-- --------------------------------------------------------

--
-- View `recipe_counts`
-- ingredient_count and step_count, worked out from the rows instead of stored.
-- Usage: SELECT * FROM recipe_counts WHERE recipe_id = 1;
--

CREATE VIEW `recipe_counts` AS
SELECT
  r.`id` AS `recipe_id`,
  (SELECT COUNT(*) FROM `ingredients` i WHERE i.`recipe_id` = r.`id`) AS `ingredient_count`,
  (SELECT COUNT(*) FROM `steps` s WHERE s.`recipe_id` = r.`id`) AS `step_count`
FROM `recipes` r;

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
