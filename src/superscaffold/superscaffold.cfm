<cffunction name="scaffold" access="public" output="false" returntype="void" mixin="controller">
	<cfargument name="modelName" type="string" required="true" hint="Model to use with this super scaffold controller" />
	<cfargument name="label" type="string" required="false" hint="the label of the form. defaults to the pluralized model name" />
	<cfargument name="actions" type="string" required="false" hint="Define what actions are available from the list. Only actions present in the list will be available." />
	<cfargument name="formats" type="string" required="false" hint="I define what formats can be requested from this super scaffold controller." />
	<cfscript>
		var loc = {};
		$args(args=arguments, name="scaffold");
		arguments.label = (StructKeyExists(arguments, "label")) ? arguments.label : capitalize(humanize(pluralize(arguments.modelName)));
		variables.$class.superScaffold = {};
		
		// translate actions
		arguments.actions = ListAppend(arguments.actions, "list,search,pagenotfound");
		if (ListFindNoCase(arguments.actions, "create"))
			arguments.actions = ListAppend(arguments.actions, "new");
		if (ListFindNoCase(arguments.actions, "update"))
			arguments.actions = ListAppend(arguments.actions, "edit");	
		if (ListFindNoCase(arguments.actions, "delete"))
			arguments.actions = ListAppend(arguments.actions, "destroy");
		
		// clean all of our lists and add them to the class data
		for (loc.item in arguments)
			if (StructKeyExists(arguments, loc.item))
				variables.$class.superScaffold[loc.item] = $listClean(arguments[loc.item]);

		// set all of our other defaults
		scaffoldList();
		scaffoldView();
		scaffoldSearch();
		scaffoldCreate();
		scaffoldUpdate();
		scaffoldDelete();
		scaffoldPermissions(roles="admin");
		
		// set a before filter to change around our action names
		filters(through="$verifyScaffoldAccess,$setModel,$defaultRequiredParams");
		
		// setup our default layout for all super scaffold admin areas
		usesLayout(template="/layouts/default", useDefault=false);
		
		// setup our provides plugin
		provides(formats=arguments.formats);
	</cfscript>
</cffunction>

<cffunction name="scaffoldAdmin" access="public" output="false" returntype="void" mixin="controller">
	<cfargument name="controllers" type="array" required="true" />
	<cfargument name="title" type="string" required="false" />
	<cfargument name="developer" type="string" required="false" />
	<cfargument name="developerLink" type="string" required="false" />
	<cfargument name="copyrightStartYear" type="numeric" required="false" />
	<cfscript>
		var loc = {};
		$args(args=arguments, name="scaffoldAdmin");
		
		variables.$class.superScaffold = {};
		application.superScaffold = Duplicate(arguments);
		// setup our default layout for all super scaffold admin areas
		usesLayout(template="/layouts/default", useDefault=false);
	</cfscript>
</cffunction>

<cffunction name="scaffoldList" access="public" output="false" returntype="void" mixin="controller" hint="This methods should be called AFTER scaffold().">
	<cfargument name="label" type="string" required="false" hint="the label of the form. defaults to the pluralized model name" />
	<cfargument name="conditionsForList" type="string" required="false" hint="a controller method name that will return a string of conditions to use in the where clause when displaying the list." />
	<cfargument name="paginationEnabled" type="boolean" required="false" hint="whether or not to use pagination" />
	<cfargument name="paginationPerPage" type="numeric" required="false" hint="the number of items per page" />
	<cfargument name="paginationWindowSize" type="numeric" required="false" hint="the size of the pagination window." />
	<cfargument name="sorting" type="string" required="false" hint="the sorting will be performed on the primary key column(s) if one is not provided" />
	<cfargument name="sortingDirection" type="string" required="false" default="asc" hint="the direction the sort should go." />
	<cfset $setSettings(methodName="scaffoldList", sectionName="list", argumentCollection=arguments) />
</cffunction>

<cffunction name="scaffoldView" access="public" output="false" returntype="void" mixin="controller" hint="This methods should be called AFTER scaffold().">
	<cfargument name="label" type="string" required="false" hint="the label of the form. defaults to the pluralized model name" />
	<cfargument name="returnToAction" type="string" required="false" hint="the name of the super scaffold action to return to if the go back link or cancel link is clicked." />
	<cfset $setSettings(methodName="scaffoldView", sectionName="view", argumentCollection=arguments) />
</cffunction>

<cffunction name="scaffoldNested" access="public" output="false" returntype="void" mixin="controller" hint="This methods should be called AFTER scaffold().">
	<cfargument name="association" type="string" required="true" />
	<cfargument name="label" type="string" required="false" default="#arguments.association#" />
	<cfscript>
		var nestedAssociation = Duplicate(arguments);
		
		if (!StructKeyExists(variables.$class, "superscaffold"))
			$throw(type="Wheels.Plugins.SuperScaffold.IncorrectMethodSequence", message="Please call `scaffold()` before calling `scaffoldNested()`.");
			
		if (!StructKeyExists(variables.$class.superscaffold, "nested"))
			variables.$class.superscaffold.nested = [];
		
		ArrayAppend(variables.$class.superscaffold.nested, nestedAssociation);
	</cfscript>
</cffunction>

<cffunction name="scaffoldSearch" access="public" output="false" returntype="void" mixin="controller" hint="This methods should be called AFTER scaffold().">
	<cfargument name="textSearch" type="string" required="false" hint="the text search can be either `first`, `last` or `full`" />
	<cfset $setSettings(methodName="scaffoldShow", sectionName="search", argumentCollection=arguments) />
</cffunction>

<cffunction name="scaffoldCreate" access="public" output="false" returntype="void" mixin="controller" hint="This methods should be called AFTER scaffold().">
	<cfargument name="label" type="string" required="false" hint="the label of the form. defaults to the pluralized model name" />
	<cfargument name="returnToAction" type="string" required="false" hint="the name of the super scaffold action to return to if the go back link or cancel link is clicked." />
	<cfargument name="beforeCreate" type="string" required="false" hint="name of the method to call before attempting to save a record. Useful to add in user session data before a save." />
	<cfargument name="afterCreate" type="string" required="false" hint="similar to beforeCreate, but after." />
	<cfargument name="multipart" type="boolean" required="false" hint="whether the form accepts multipart data (aka: file uploads)" />
	<cfset $setSettings(methodName="scaffoldCreate", sectionName="create", argumentCollection=arguments) />
</cffunction>

<cffunction name="scaffoldUpdate" access="public" output="false" returntype="void" mixin="controller" hint="This methods should be called AFTER scaffold().">
	<cfargument name="label" type="string" required="false" hint="the label of the form. defaults to the pluralized model name" />
	<cfargument name="returnToAction" type="string" required="false" hint="the name of the super scaffold action to return to if the go back link or cancel link is clicked." />
	<cfargument name="beforeUpdate" type="string" required="false" hint="name of the method to call before attempting to save a record. Useful to add in user session data before a save." />
	<cfargument name="afterUpdate" type="string" required="false" hint="similar to beforeCreate, but after." />
	<cfargument name="multipart" type="boolean" required="false" hint="whether the form accepts multipart data (aka: file uploads)" />
	<cfset $setSettings(methodName="scaffoldUpdate", sectionName="update", argumentCollection=arguments) />
</cffunction>

<cffunction name="scaffoldDelete" access="public" output="false" returntype="void" mixin="controller" hint="This methods should be called AFTER scaffold().">
	<cfargument name="returnToAction" type="string" required="false" hint="the name of the super scaffold action to return to if the go back link or cancel link is clicked." />
	<cfargument name="beforeDelete" type="string" required="false" hint="name of the method to call before attempting to delete a record. Useful to add in user session data before a save." />
	<cfset $setSettings(methodName="scaffoldDelete", sectionName="delete", argumentCollection=arguments) />
</cffunction>

<cffunction name="scaffoldPermissions" access="public" output="false" returntype="void" mixin="controller" hint="This method should be called AFTER scaffold().">
	<cfargument name="roles" type="string" required="false" default="" />
	<cfscript>
		var loc = { areas = "list,view,nested,new,create,edit,update,delete,destroy" };
		
		if (!StructKeyExists(variables.$class, "superscaffold"))
			$throw(type="Wheels.Plugins.SuperScaffold.IncorrectMethodSequence", message="Please call `scaffold()` before calling `scaffoldPermissions()`.");
		
		for (loc.i = 1; loc.i lte ListLen(loc.areas); loc.i++)
		{
			loc.area = ListGetAt(loc.areas, loc.i);
			
			if (!StructKeyExists(variables.$class.superscaffold, loc.area))
				variables.$class.superscaffold[loc.area] = {};
			
			if (StructKeyExists(arguments, loc.area))
				variables.$class.superscaffold[loc.area].roles = arguments[loc.area];
			else if (Len(arguments.roles))
				variables.$class.superscaffold[loc.area].roles = arguments.roles;
			else
				variables.$class.superscaffold[loc.area].roles = "all";
		}
		
		
		$dump(variables.$class);
			
		if (!StructKeyExists(variables.$class.superscaffold, "nested"))
			variables.$class.superscaffold.nested = [];
	</cfscript>
</cffunction>




