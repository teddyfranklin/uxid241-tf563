-- beta.sql - run AFTER assets/database/schema.sql
-- AI: generated with Claude Code (entire file).
--
-- 1. Makes sure the `users` table exists (schema.sql creates it, but this keeps
--    beta.sql safe to run on its own).
-- 2. Seeds the one admin account. Beta has no public registration, so this is
--    the only way in. The login details are in the README.
--
-- The value below is a password_hash() (bcrypt, "$2y$...") result made locally with
-- beta/database/hash_password.php (run it from a terminal: php beta/database/hash_password.php).
-- The plaintext password is never stored in the database.
-- Re-running this file resets the admin's password back to the README value.

CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `users` (`email`, `password_hash`) VALUES
('admin@example.com', '$2y$10$bFVk5ScfC3imAcvpnnVDNeGzu47i5TPiLeNsbTiXUTe4GC65TIlPS')
ON DUPLICATE KEY UPDATE `password_hash` = VALUES(`password_hash`);
