This is where Beyond Z participants login and access their leadership development portal.

== Getting Started ==

To get started, fork this repository on Github. Then, use "git clone your_forked_url" to create a local copy.

Run "git remote add upstream https://github.com/beyond-z/beyondz-platform.git" to make the upstream code available.


Always branch when working on a new feature:

	git branch feature_name
	git checkout feature_name

When you are ready, commit with "git commit -a -m 'a brief message saying what you did'".

Push your changes back to github with:

	git push origin feature_name

Once you are ready for it to be tested, select the branch from your github page using the drop down selector. Then click the green pull request button to the left hand side of the drop down.

On the next screen, click "Edit" near the right-hand side of the screen to choose the Staging branch on beyondz-platform.

Write a message telling what you did, then submit the pull request.


To get changes from staging into your local branch, run

	git pull upstream staging

This will keep you up to date.

== Code style ==

We use standard Rails code conventions with some additional rules:

  * Indent each level with two spaces
  * Write the main class at the top of the file. Try to stick to one class per file, but a small helper (e.g. an exception subtype) may appear below the main class.
  * Always use begin, raise, and rescue for error handling. Don't use throw and catch in Ruby.
  * Always raise subclasses of Exception specialized to your need, and always rescue a specific type.
  * Write empty parenthesis on zero-argument method calls so they don't look like properties.
  * Always use Rails database migrations when adding new data.
  * Keep individual lines simple. If a new reader can't immediately tell what it is doing, either simplify the code or refactor it into a named method.
  * Use the flash hash to quick message workflows.
  * Never commit a FIXME: either fix it or make a task in Asana.
