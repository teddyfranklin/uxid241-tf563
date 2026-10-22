<?php
declare(strict_types=1);

/*
 * STEPS DEMO
 * ----------
 * Shows the three ideas from the professor's "recipe steps" demo:
 *   1. What $_POST is (just an array of whatever the form sent).
 *   2. How several inputs named step[] become ONE array in PHP.
 *   3. How implode() squashes that array into ONE string for ONE column,
 *      and how explode() turns it back into a list when you read it.
 *
 * There is NO real database here on purpose, so this page works even when
 * MySQL isn't running. A PHP session stands in for the database: it remembers
 * the "steps column" for our fake recipe between page loads.
 */

// session_start() lets $_SESSION survive from one request to the next.
// Think of $_SESSION['recipes'] as a tiny pretend "recipes" table.
session_start();

// The recipe we're editing. In the real project this id would come from the
// URL or the database. It already exists BEFORE the form is submitted,
// which is why it's the recipe's id and not a step's id.
$id = 1;

// The separator placed between steps. Whatever you choose here must never
// appear inside a step, or reading the steps back will split in the wrong place.
const STEP_SEPARATOR = '*';

/*
 * Stand-in for the professor's add_steps($conn, $id, $steps).
 * The real version would run something like an UPDATE on the recipe's row.
 * This one just saves the string in the session "table" under the recipe id.
 * Notice it receives ONE string, not a list: one recipe, one steps value.
 */
function add_steps(int $id, string $steps): void
{
    $_SESSION['recipes'][$id]['steps'] = $steps;
}

/*
 * The mirror image of saving: fetch the single string and split it back
 * into a list with explode(). Returns an empty array if nothing is saved.
 */
function get_steps(int $id): array
{
    $stored = $_SESSION['recipes'][$id]['steps'] ?? '';

    // explode('*', '') would return [''] (a list with one empty item),
    // so handle "nothing saved" separately.
    if ($stored === '') {
        return [];
    }

    return explode(STEP_SEPARATOR, $stored);
}

// These hold information for the "what just happened" panel further down.
$raw_post = null;     // a copy of $_POST, to show exactly what arrived
$submitted = [];      // the step[] array as it arrived
$imploded = null;     // the single string we built from it
$separator_warning = false;

/*
 * $_POST is only filled when a form is SUBMITTED with method="post".
 * On a normal page load (a GET request) this whole block is skipped.
 */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $raw_post = $_POST;

    if (isset($_POST['reset'])) {
        // The "Clear saved steps" button: forget everything for this recipe.
        unset($_SESSION['recipes'][$id]);
    } else {
        // Every input named step[] lands here as ONE array, in page order.
        // "?? []" means: if no step inputs were sent at all, use an empty array.
        $step_list = $_POST['step'] ?? [];

        // trim() removes surrounding spaces. array_filter() then drops boxes
        // that were left blank, so they don't become empty steps.
        // (The professor's version doesn't do this. It's an extra tidy-up.)
        $step_list = array_values(array_filter(array_map('trim', $step_list), 'strlen'));
        $submitted = $step_list;

        // Check the edge case: does any step contain the separator itself?
        foreach ($step_list as $step) {
            if (str_contains($step, STEP_SEPARATOR)) {
                $separator_warning = true;
            }
        }

        if ($step_list !== []) {
            // implode() glues the array items into one string, putting
            // STEP_SEPARATOR between each one.
            // ['Boil water', 'Add pasta'] becomes 'Boil water*Add pasta'
            $imploded = implode(STEP_SEPARATOR, $step_list);
            add_steps($id, $imploded);
        }
    }
}

// Read the steps back the way a "view recipe" page would.
$saved_steps = get_steps($id);
$saved_string = $_SESSION['recipes'][$id]['steps'] ?? '';

// Shortcut for safely printing user text into HTML. htmlspecialchars()
// turns characters like < and > into harmless text so typed input can't
// inject HTML. Always escape on the way OUT to the page.
function e(string $text): string
{
    return htmlspecialchars($text, ENT_QUOTES, 'UTF-8');
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Steps Demo</title>
    <style>
        body { font-family: system-ui, sans-serif; max-width: 760px; margin: 2rem auto; padding: 0 1rem; line-height: 1.5; }
        section { border: 1px solid #ccc; border-radius: 8px; padding: 1rem 1.25rem; margin-bottom: 1.25rem; }
        h2 { margin-top: 0; font-size: 1.1rem; }
        .step-row { display: flex; gap: .5rem; margin-bottom: .5rem; }
        .step-row input { flex: 1; padding: .4rem; }
        pre { background: #f4f4f4; padding: .75rem; overflow-x: auto; white-space: pre-wrap; }
        .warning { background: #fff3cd; border-color: #e0c060; }
        code { background: #f4f4f4; padding: 0 .25rem; }
    </style>
</head>
<body>

<h1>Recipe steps demo</h1>
<p>Type a few steps, add more boxes if you like, then save. The panels below show
what PHP received and how it was stored. Try a step like <code>Bake at 350* F</code>
to see the separator problem.</p>

<!--
    1 + 2: THE FORM
    method="post" makes the browser send the fields in the request body,
    and PHP unpacks them into $_POST.
    Every text box has the SAME name: step[]. The [] tells PHP to collect
    all of them into one array, $_POST['step'], instead of the last box
    overwriting the others.
-->
<section>
    <h2>1. The form (every box is named <code>step[]</code>)</h2>
    <form method="post">
        <div id="steps">
            <div class="step-row"><input type="text" name="step[]" placeholder="Step 1"></div>
            <div class="step-row"><input type="text" name="step[]" placeholder="Step 2"></div>
        </div>

        <!-- type="button" stops this button from submitting the form. -->
        <button type="button" id="add-step">+ Add another step</button>
        <button type="submit">Save steps</button>
    </form>

    <!-- A separate tiny form, so the reset button sends "reset" instead of steps. -->
    <form method="post" style="margin-top:.75rem">
        <button type="submit" name="reset" value="1">Clear saved steps</button>
    </form>
</section>

<?php if ($raw_post !== null): ?>
    <!-- Only shown right after a submission, because $_POST is empty otherwise. -->
    <section>
        <h2>2. What arrived in <code>$_POST</code></h2>
        <p>Just an array. Notice <code>step</code> is itself an array with one item per box.
            Spaces inside a box never split anything.</p>
        <pre><?= e(print_r($raw_post, true)) ?></pre>
    </section>

    <?php if ($imploded !== null): ?>
        <section>
            <h2>3. After <code>implode('<?= e(STEP_SEPARATOR) ?>', ...)</code></h2>
            <p><?= count($submitted) ?> step(s) became this ONE string, which is what
                <code>add_steps()</code> saved into the recipe's single steps column:</p>
            <pre><?= e($imploded) ?></pre>
        </section>
    <?php endif; ?>
<?php endif; ?>

<?php if ($separator_warning): ?>
    <section class="warning">
        <h2>Separator problem</h2>
        <p>One of your steps contains <code><?= e(STEP_SEPARATOR) ?></code>. The saved string can't
            tell that apart from the gap between steps, so reading it back produces
            <strong><?= count($saved_steps) ?></strong> steps instead of
            <strong><?= count($submitted) ?></strong>. A separate steps table (one row per step)
            avoids this.</p>
    </section>
<?php endif; ?>

<!--
    READING IT BACK
    This is what a "view recipe" page would do: take the one string from the
    column, explode() it on the separator, and loop over the pieces.
-->
<section>
    <h2>4. Reading it back with <code>explode()</code> (recipe #<?= $id ?>)</h2>
    <?php if ($saved_steps === []): ?>
        <p>No steps saved yet.</p>
    <?php else: ?>
        <p>Stored string: <code><?= e($saved_string) ?></code></p>
        <ol>
            <?php foreach ($saved_steps as $step): ?>
                <li><?= e($step) ?></li>
            <?php endforeach; ?>
        </ol>
    <?php endif; ?>
</section>

<script>
    // The "Add another step" button. Each click adds a new input with the SAME
    // name, step[], so PHP will simply see one more item in the array.
    // This runs in the browser only; PHP never sees this code.
    document.getElementById('add-step').addEventListener('click', function () {
        const container = document.getElementById('steps');
        const count = container.children.length + 1;

        const row = document.createElement('div');
        row.className = 'step-row';

        const input = document.createElement('input');
        input.type = 'text';
        input.name = 'step[]';
        input.placeholder = 'Step ' + count;

        row.appendChild(input);
        container.appendChild(row);
        input.focus();
    });
</script>

</body>
</html>
