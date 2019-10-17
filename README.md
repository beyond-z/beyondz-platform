This is where various Braven stakeholders go to signup/apply to participate in Braven.

# Getting Started

## Docker Setup
1. Add these variables to your `~/.bash_profile` (see: https://drive.google.com/a/bebraven.org/file/d/1AiwrCKZ11-BjNxIIP6qfD9B9rQvmfMY2/view?usp=sharing for the values to enter): 
```
export DATABASEDOTCOM_CLIENT_ID=<client_id>
export DATABASEDOTCOM_CLIENT_SECRET=<client_secret>
export SALESFORCE_USERNAME=<username>
export SALESFORCE_PASSWORD=<pw>
export SALESFORCE_SECURITY_TOKEN=<security_token>
export SALESFORCE_MAGIC_TOKEN=<magic_token>
```

2. Run `source ~/.bash_profile` (or you could restart the Terminal)

3. Follow the instructions at: https://github.com/beyond-z/development

Then, from your application root just run:

When complete, the app will be available at: `http://joinweb`

Note: you may have to restart a couple of the services, like `rubycas-server` and `nginx-dev` the very first time since
there is so much going on and timing issues crop up with the initial databases loading and becoming available to the apps.

Some things to keep in mind with Docker:
* If there are build errors, run `docker-compose logs` to see what they
  are.
* The environment variables come from `docker-compose/.env-docker`
* If you change environment variables, restart to have them picked up by
  running `./docker-compose/scripts/restart.sh
* There are more scripts in `./docker-compose/scripts` to help you work
  with the container(s).

## Development Process

Have a look at [this section](https://github.com/beyond-z/development/blob/master/README.md#development) of the overall development setup for our entire enviornment (all apps) for an overview.

When you do something in the development environment that integrates with Salesforce, it's done in the [BVDev Sandbox](https://test.salesforce.com). If you don't have a login to this Sandbox, ask your Team Lead to set it up for you.

### Continuous Integration
### NOTE: this is currently broken. We either need to fix it up or cutover to our new CI flow.
We use a continuous integration test server on all pull requests. When you
open a pull request, it will be automatically tested and the results displayed
on GitHub in the form of a checkbox or an X mark.

The current integration runs the test suite as well as rubocop. Any errors resulting from either will show as a failure.

You can see the details [here](https://travis-ci.org/beyond-z/beyondz-platform)

# External Integrations
In the development environment, these integrations are already setup for you to just work. But here is some background on how they are setup in general.

## [Salesforce.com](https://login.salesforce.com)
When folks signup and apply to be a part of Braven, their information is sent to Salesforce.

### Configs Needed To Integrate with Salesforce.com

On the site, go to Setup -> Build on left hand side -> Create -> Apps. There, you can make an app. Enable OAuth and put in the site as the callback URL. It will then make the ID and Secret available to you.

```
DATABASEDOTCOM_CLIENT_ID=<from salesforce>
DATABASEDOTCOM_CLIENT_SECRET=<from salesforce>
```

Those two variables are managed by the gem and thus must be present, but are not used explicitly in any of our code.

Click Your Name -> Settings (upper right). Go to Personal -> Reset My Security Token (same menu as change password). It emails you the token
This, along with your username and password, will be used by the app to log in as you and create the new contacts.

```
SALESFORCE_USERNAME=<email address to log into salesforce>
SALESFORCE_PASSWORD=<password log into salesforce>
SALESFORCE_SECURITY_TOKEN=<token gotten from salesforce email>
```

## [Portal](https://portal.bebraven.org)

### Configs Needed To Integrate with Canvas
Five environment variables relate to using the Canvas LMS through its REST API:

```
CANVAS_ACCESS_TOKEN=<token created in canvas admin for app integration>
CANVAS_SERVER=<domain of canvas server>
CANVAS_PORT=<port of canvas server>
CANVAS_USE_SSL=<true or false>
CANVAS_ALLOW_SELF_SIGNED_SSL=<true or false>
```
These are self explanatory except for the canvas access token. To create one of these, log into Canvas as the admin user and click settings (upper right corner of the screen). Scroll down to "Approved Integrations" and generate a new access token. That is the value needed for CANVAS_ACCESS_TOKEN.

# Coding Conventions

## Ruby/Rails

We use standard Rails code conventions with some additional rules:

  * Indent each level with two spaces
  * Always raise subclasses of Exception specialized to your need, and always rescue a specific type.
  * Always use Rails database migrations when adding new data.
  * Write the main class at the top of the file. Try to stick to one class per file, but a small helper (e.g. an exception subtype) may appear below the main class.
  * Always use begin, raise, and rescue for error handling. Don't use throw and catch in Ruby.
  * Keep individual lines simple. If a new reader can't immediately tell what it is doing, either simplify the code or refactor it into a named method.
  * Use the flash hash to quick message workflows.
  * Never commit a FIXME: either fix it or make a task in Asana.

This is the full style guide we adhere to: https://github.com/bbatsov/ruby-style-guide

Remember to run rubocop before submitting pull requests to help keep code up to standards.

## CSS

Structure CSS files according to the ![asset management guide](app/assets/asset_management_guide.pdf).

  * Avoid placing CSS in view files.
  * Indent each level with two spaces
  * Use dashes in class/id names, not underscores.
  
	**Fig. 1**
  
	```
	.content-container ...

	// NOT
	.content_container ...
	```
  * Beginning curly brace should be on the same line as the class name (see fig 2).
  * Ending curly brace should be vertically inline with the class name (see fig 2).
  * Use empty lines between class definitions (see fig 2).
  
  	**Fig. 2**
  	```
	body {
	  background-color: #fff;
	}
					// <-- empty line
  	.content-container {
  	  color: #eee;
  	  width: 100%;
  					// <-- empty line
	  .section {
		font-size: 1.5em;
	  }
	}

  	// NOT
  	.content-container { ... }
  	
	// OR
	.content-section
	{
	  ...
	}
  	```
  * Use Bootstrap styles and components (CSS and JS) whenever possible (see fig 3).
  * Whenever possible, avoid using Bootstrap classes directly in view files. Instead, create a class that extends Bootstrap classes (see fig 3). This doesn't mean that you create a custom class for everything. You can use Bootstrap classes in the HTML, but opt for using existing defined styles or abstracting to more generic reusable styles that extend Bootstrap.
  	
	**Fig. 3**
  	```
  	// in the CSS
  	.attachment-button {
      @extend .btn;
      @extend .btn-default;
      @extend .glyphicon;
      @extend .glyphicon-paperclip;
      margin-right: 2em;
      float: left;
    }
    
	// in the HTML
	<button id="attachment-button"></button>
    
	// NOT
	// in the CSS
  	.attachment-button {
      float: left;
    }
    
	// in the HTML
	<button id="attachment-button btn btn-default glyphicon glyphicon-paperclip"></button>
  	```
  * Utilize SASS, but minimize nesting. Be aware of bloat and cascading brittleness (see fig 4).
  * All styles should be properly scoped so that generic classes like ".document" or ".form" don't accidentally override other styles. Instead use something like ".comment .document" or ".comment form" to limit their application.
  	
	**Fig. 4**
  	```
  	// This scopes the generic elements sufficiently under a unique
  	// "special-form" class. If the designer wanted to move the "button-1"
  	// HTML element inside either column, the style would still apply.
  	// This also scopes the generic classes like 'column-1' under a
  	// unique class 'special-form'.
  	
  	.special-form {
  	  .column-1 {
  	  	...
  	  }
  	  
	  .column-2 {
	    ...
	  }
	  
	  .button-1 {
	  	...
	  }
	  
	  .button-2 {
	  	...
	  }
	}
	
	// NOT
	// This creates unnecessary class definition length and restricts minor
	// design changes because the CSS nesting mimics the HTML nesting.  If the
	// designer wanted to move the "button-1" HTML element inside of the
	// "column-1" HTML element, the style would NOT be applied.
	
	.special-form {
  	  .column-1 {
  	  	...
  	  }
  	  
	  .column-2 {
	  	...
	  	
	  	.button-1 {
	 	  ...
	 	}
	  
	  	.button-2 {
	  	  ...
	  	}
	  }
	}
  	```
  * Consider refactoring and generalizing styles into the asset management structure to maximize reuse.
  * Try to use scalable sizing for all elements. Opt for "em" over "px" (see fig 5).
  * Choose semantic concepts for styles over those that are page specific, mapped to HTML structures, or style descriptions.
  	
  	**Fig. 5**
  	```
  	// Do's
  	.page-header {
      font-size: 2em;
      width: 100%;
  	}
  	
	.basic-list {
	  margin-top: 3em;
	  
		li {
		  color: #eee;
		}
	}
	
	// name is not overly style descriptive
	.thick-bottom-line {
	  border-bottom: solid 10px #f00;
	}
	
	// reusable class extends generic class (but could extend .thin-bottom-line)
	.page-title {
	  @extend .thick-bottom-line;
	  
	}

  	// Dont's
  	.contact-page-header {
  	  font-size: 16px;
  	  width: 100%;
  	}
  	
	.article-list {
	  margin-top: 10px;
	  
		.article-list-item {
		  color: #eee;
		}
	}
	
	.line_10px_red {
	  border-bottom: solid 10px #f00;
	}
  ```
  * When possible use CSS selectors that address tags instead of custom names. This will reduce extraneous class definitions and HTML bloat. It also makes the CSS clear as to what type of element is being referenced without having to traverse the HTML.
  
  **Fig. 6**
  ```
  	// If you know that "special-form" is a form and had a submit button
  	// there is rarely a need to give it an id or class and define a named
  	// CSS style for it.
  	
  	.special-form {
  	  .input[type=submit] {
  	  	...
  	  }
  	}
	
	// NOT	
	.special-form {
  	  .submit-button {
  	  	...
  	  }
	}
  	```
  
  * See https://www.dropbox.com/s/hzy0mt1jeh4ns4t/bz-colors-02.pdf for our color palette documentation. The palette code is found in app/assets/stylesheet/base/palettes/_primary.css.scss

  * Body text will use only white or dark gray (or extra dark): see txt-dk and txt-lt in code. Links will only use shades of blue. link-* in code. Brand orange is reserved primarily for CTA (call to action) buttons/areas. Three colors and grays give a total of 15 swatches (+2 for extra light/dark text). cta* in code.

## JavaScript

Structure JS files according to the ![asset management guide](app/assets/asset_management_guide.pdf).

  * Avoid placing JS in view files.
  * Indent each level with two spaces
  * Use Bootstrap components wherever possible.
  * Use JQuery for additional components or to add interactivity, etc...
  * Use inline curly braces.
  	```
  	say_hello = function()
  	{
  	  ...
  	}
  	
	if(true)
	{
	  ...
	}
	else
	{
	  ...
	}
	
	// NOT	
	say_hello = function(){
  	  ...
  	}
  	
	if(true){
	  ...
	}
	else{
	  ...
	}
	```
  * Properly scope selectors so to avoid side effects on other elements (see below).
  * Reuse selector variables wherever possible. No need to continually reselect the same HTML elements.
  	```
  	var list_items = $('.basic-list li');
  	
	list_items.hide();
	list_items.show();
  	
	
	// NOT	
	$('li').hide();
	$('li').show();
	```
