# uxid241-tf563
- This repo contains the project files for the uxid241 course, which is a project focused on using PHP and SQL for an online cookbook.

## What is this project?
- It is a cookbook site connected to a database. Visitors can browse recipes, search them by title, filter by category, and open a recipe to see its ingredients, steps and tips. An admin can sign in and create, edit and delete recipes. It is built with functional PHP (mysqli) and MySQL.
- The current milestone is **beta**, in the `beta/` folder. `Alpha/` is kept as the alpha milestone.
- Repo layout: `beta/` and `Alpha/` are the cookbook project, and `assets/` holds what they share (database config and schema, styles, alpha's search script). `Assignments/` holds the weekly assignments. `Practice/` is personal practice and tutorial follow-alongs, not part of the project, so it isn't held to the project's conventions (e.g. `declare(strict_types=1)`, snake_case).

## How to run locally
- Install MAMP (Mac) or XAMPP (Windows)
- Place project in the htdocs folder (`/Applications/MAMP/htdocs` or `C:\xampp\htdocs`)
- Start Apache and MySQL, then in phpMyAdmin:
  1. Create an empty database named `recipe_db`
  2. Import `assets/database/schema.sql` (tables + the 40 recipes)
  3. Import `beta/database/beta.sql` (seeds the admin account below)
- Credentials are picked automatically in `assets/database/config.php`:
  - XAMPP on Windows: `root`, no password, port 3306
  - MAMP on Mac: `root` / `root`, port 8889
- If your setup is different (e.g. MAMP on Windows, a custom port or password), copy `assets/database/config.local.example.php` to `config.local.php` and edit it. That file is gitignored.
- Open the beta site at `http://localhost/uxid241-tf563/beta/` (MAMP: `http://localhost:8888/uxid241-tf563/beta/`).
- Requires PHP 8.2+ (uses `mysqli_execute_query`). Current XAMPP/MAMP ship with it.

## Admin login (beta)
- Beta uses a **seeded admin account**; there is no public registration, so random visitors can't give themselves admin access.
- Email: `admin@example.com`
- Password: `cookbook-admin-2026`
- This is a local test account. The database only stores its `password_hash()` (bcrypt) hash, in `beta/database/beta.sql`. Re-importing `beta.sql` resets the password to the one above.
- To change the admin password: run `php beta/database/hash_password.php` in a terminal (XAMPP: `C:\xampp\php\php.exe beta\database\hash_password.php`), type the new password, paste the printed hash into `beta.sql`, and re-import it. The script only runs from the command line; through the browser it returns 404.
- Log in from the "Admin log in" link on any page, or go to `beta/login.php`.

## Beta features
- **CRUD on recipes**
  - Create: `beta/admin/create.php`. Edit: `beta/admin/edit.php?id=…`. Delete: `beta/admin/delete.php?id=…` (asks to confirm; deletes only on POST).
  - Read: the public list (`beta/index.php`) and a recipe page (`beta/recipe.php?id=…`).
  - The form covers title, subtitle, category, servings, description, image path and ingredients (one per line). Steps, tools and tips are shown on the recipe page but aren't editable yet.
  - Every query lives in `beta/functions.php` and goes through `mysqli_execute_query` (a prepared statement: prepare, bind, execute). No SQL is built from user input.
  - Input is validated on the server (`validate_recipe`) before anything is written. Every value printed to a page goes through `htmlspecialchars`.
  - Create and edit write several tables inside one transaction. Delete is `DELETE FROM recipes WHERE id = ?`, and the foreign keys' `ON DELETE CASCADE` removes that recipe's ingredients, steps, tools and tips.
- **Authentication**
  - `beta/login.php` looks the user up by email (prepared statement) and checks the password with `password_verify`.
  - On success it calls `session_regenerate_id(true)` and stores only the user id in `$_SESSION`.
  - Both a bad email and a bad password show the same message: "Invalid email or password."
- **Admin guard**
  - Every page in `beta/admin/` first requires `beta/guard.php`, which redirects logged-out visitors to `login.php` and then calls `exit`.
  - The session cookie is `httponly` and `SameSite=Lax` (`beta/session.php`).
- **Chosen feature: Search**
  - The search box on `beta/index.php` finds recipes by title with a prepared statement and a `LIKE ?` parameter (`search_recipes` in `beta/functions.php`).
  - `%` and `_` typed by the user are escaped so they're searched literally.
  - Results update as you type (`beta/scripts/search.js` fetches `beta/search.php`). Without JavaScript, the form still works as a normal GET search.
  - The category filter from alpha is still there as a bonus, also through a prepared statement.

## AI use
- Assignment 2: Majority of code written by claude code on top of handwritten HTML input forms and other basic setup. Comments are my own. I will rewrite this by hand to better my understanding of form validation. 
- Assignment 3: Claude code was used to troubleshoot bugs that prevented the recipe list from printing to the site. 
- Alpha: Schema.sql normalization change was written using claude code using concepts gleaned from "Database System Concepts 7th Edition." Frontend CSS and HTML generated using a claude to Figma connector. I explained this part incorrectly and believe you thought I meant the frontend was literally connected to figma via a server, but it is simply CSS and HTML generated to spec using markdown skills published by Figma. Search.php and search.js were also generated by Claude but those may have already been rewritten by hand by the time you grade this assignment. The readme and header comments will change accordingly. 

- Authentication and session PHP generated with claude based on direction gleaned from snippets found in the lecture notes. File structure and user SQL table schema were written by hand. 

- Beta: Claude Code (Claude Opus) was used as a "junior developer" to build the beta milestone. I made the design decisions: flattening the folder, a seeded admin instead of open registration, which fields the form edits, and Search as the graded feature. Claude wrote the code to those decisions.
  - Generated by Claude: `beta/functions.php` (CRUD, search and validation queries), the admin pages (`beta/admin/*.php`), `beta/recipe.php`, `beta/search.php`, the partials (`beta/partials/*.php`), `beta/styles/beta.css` and `beta/database/beta.sql`.
  - Carried over from alpha with small changes (AI-generated in alpha, from lecture snippets): `beta/session.php`, `beta/guard.php`, `beta/login.php`, `beta/logout.php`, `beta/index.php`, `beta/scripts/search.js`.
  - Every AI-generated file has an `AI:` comment at the top saying so.
  - Claude also tested the site locally: logged-out redirects, login and the vague error, create/edit/delete, and search input such as `'` and `%`.
  - I reviewed the auth and CRUD code against the week 6 and week 7 lectures.
