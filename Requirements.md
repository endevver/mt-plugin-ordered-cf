# Requirements document for OrderedCF Plugin #

This document outlines the context and initial requirements for the "Custom
Field Re-ordering Plugin".

## Problem Statements ##

   * The list of fields on the edit entry screen can be unwieldy and not all
     need to be visible.
   
   * There is an ideal order of custom fields to facilitate a blog's
     publishing workflow, e.g. one field relates to another. When this
     happens it is frustrating and confusing when those fields are not
     juxtaposed to one another.
   
   * Editors are concerned that others will not fill out the edit entry form
     correctly if they do not see the field, or if the fields are in the wrong
     order.
   
   * What fields are visible and not visible do not appear to be consistent or
     relate to a user's stated preference. In other words, the field ordering I
     create can sometimes be reset seemingly randomly.
   
## Solution Overview ##

We need to provide a way for editors and admins of a blog to specify the
default order and visibility preferences of a blog's edit entry (and page)
fields when a user has not customized the display themselves.

## Requirements ##

   * If a user has customized the order of fields themselves, then that order
     should be respected.

   * If a user has not customized the order of fields themselves, then the
     order of fields should be presented in a way consistent with what the
     editor/admin of the blog has specified.

   * If the editor has not specified a default order, then fall back to the
     default MT/Melody presentation.

## Desired UX ##

One of the following:

   1. Add a checkbox to the display options fly out that says "Save as
      default for all users" that when clicked will save the field ordering 
      and visibility preferences for all users.

   2. Create a Blog Preference which replicates the Display Options fly out
      ability to drag and drop fields in the preferred order, and allows user 
      to set the field's visibility status.

