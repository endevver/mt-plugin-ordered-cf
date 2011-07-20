# Ordered Custom Fields plugin for Melody and Movable Type v4.3x #

An plugin for MT 4.3x and Melody installations with the Movable Type
Commercial pack (or better) installed which allows for ordering and
persistence of custom and native fields.

## FEATURES ##

* Users can reorder native and custom fields for each supported object type
  and save that preference on a per-object, per-blog basis.

* System and blog administrators can additionally save the field order as the
  blog's default order for each supported object type.

    * The default is used by any user who has not already customized their
      field order for the object type and blog.

* Currently supported object types: Entries and Pages

    * Each object type has its *own storage space* for user preferences and
      blog defaults meaning entries and pages no longer clobber each other!

## PLUGIN REQUIREMENTS ##

   * Any version of [Melody][] or [Movable Type v4.3x][MT]

   * The [Movable Type Pro pack][MTPro] or better, specifically
     Commercial.pack

   * The [Melody-compat plugin][]

[MT]:                   http://movabletype.org/
[MTPro]:                http://movabletype.com/
[Melody]:               http://openmelody.org/
[Melody-compat plugin]: https://github.com/endevver/mt-plugin-melody-compat

## LICENSE ##

This plugin is licensed under the same terms as Perl itself.

## INSTALLATION ##

Unzip the download archive. Move the resulting folder to `$MT_HOME/plugins/`
(where `$MT_HOME` is your MT or Melody application directory).

If you use Git, you can do the following:

    cd $MT_HOME/plugins
    git clone git://github.com/endevver/mt-plugin-ordered-cf.git

## CONFIGURATION ##

There is no configuration for this plugin.

## USAGE ##

Go to the editing screen for any object of a supported object type. All
supported object types will have a Display Options panel located on that page.

Using the options on that panel, you can reorder and hide/show fields and save
that and other preferences. Preferences are usually specific to the user,
object type and blog.

System administrators and administrators of the current blog can opt to save
the preference as a blog default for that object type.

## LIMITATIONS ##

The plugin currently only supports **entries** and **pages** since those two
object types already have Display options panels. 

## FUTURE PLANS ##

Support for all other object types CustomFields supports will be added soon.

## HELP, BUGS AND FEATURE REQUESTS ##

If you are having problems installing or using the plugin, please check out our general knowledge base and help ticket system at [help.endevver.com](http://help.endevver.com).

## COPYRIGHT ##

Copyright 2011, Endevver, LLC. All rights reserved.

## ABOUT ENDEVVER ##

We design and develop web sites, products and services with a focus on 
simplicity, sound design, ease of use and community. We specialize in 
Movable Type and offer numerous services and packages to help customers 
make the most of this powerful publishing platform.

http://www.endevver.com/
