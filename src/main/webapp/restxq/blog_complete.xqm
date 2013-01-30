(:~
 : This module contains a basic blog example demonstrating how to develop
 : a simpl RESTXQ web applications with BaseX.
 :
 : This complete version shows:
 : - the basics of RESTXQ annotations
 : - how to create html output
 :
 : - how to create and drop a database (For more details see
 :   http://docs.basex.org/wiki/Database_Module)
 :
 : - how to insert nodes into the database
 : - how to delete nodes from the database
 : - how to modify/replace nodes within the database
 :   (For more details about XQuery Update Facility functions 
 :   see http://docs.basex.org/wiki/XQuery_Update)
 :
 : - how to combine updating and non-updating expressions using
 :   restxq:redirect and db:output()
 :
 : @author BaseX Team
 :)
module namespace page = 'http://basex.org/modules/web-page';


(:~
 : The main page of the blog.
 :
 : If the blog database does not yet exist, the user must create one in order
 : to start working on the blog.
 :)
declare %restxq:path("blog-complete")
        %output:method("xhtml")
        %output:omit-xml-declaration("no")
        %output:doctype-public("-//W3C//DTD XHTML 1.0 Transitional//EN")
        %output:doctype-system("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")
        function page:show-blog() {

  (: Check whether the blog database exists. :)
  let $result := if (db:exists("my-blog")) then
                   page:site-content-if-blog-db-exists()
                 else
                   page:site-content-if-blog-db-does-not-exist()
  return $result
};


(:~
 : If the blog database does not yet exist, the user is requested on the main page
 : to create one.
 :
 : @RETURN     Content of main page if blog database does not exist.
 :)
declare %output:method("xhtml")
        %output:omit-xml-declaration("no")
        %output:doctype-public("-//W3C//DTD XHTML 1.0 Transitional//EN")
        %output:doctype-system("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")
        function page:site-content-if-blog-db-does-not-exist()
{

  let $title := 'Welcome to your new blog!'
  
  return
   <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{ $title }</title>
      <link rel="stylesheet" type="text/css" href="/style.css"/>
    </head>
    <body>
      <div class="right"><img src="/basex.svg" width="96"/></div>
      <h2>{ $title }</h2>

      <p>You have to <a href="blog-complete/create-database">create the blog database</a> first.</p>
    </body>
  </html>
};


(:~
 : If the blog database does exist, the user can start to write postings or edit the blog's
 : settings.
 :
 : @RETURN          Content of main page if blog database exists.
 :)
declare %output:method("xhtml")
        %output:omit-xml-declaration("no")
        %output:doctype-public("-//W3C//DTD XHTML 1.0 Transitional//EN")
        %output:doctype-system("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")
        function page:site-content-if-blog-db-exists()
{

  (: Open blog database. :)
  let $db := db:open("my-blog")
  
  (: Create page title using the user-specified name of the blog. :)
  let $blog := if (fn:string-length(fn:normalize-space($db/blog/blogname/text())) != 0) then
                 $db/blog/blogname/text()
               else
                 "your new blog"
  let $title := 'Welcome to ' || $blog || '!'
  
  (: Create and format the blog's postings. :)
  let $author := if (fn:string-length(fn:normalize-space($db/blog/blogauthor/name/text())) != 0) then
                   $db/blog/blogauthor/name/text()
                 else
                   "the blog's author"
  let $postings := for $posting in $db/blog/postings/posting
                   let $r := <p><small>On {fn:substring(string($posting/@postingdate), 0, 11) || " at " || 
                                fn:substring(string($posting/@postingdate), 12, 5) || " " || $author } posted: </small><br />
                               <b>{ $posting/postingtitle/text() }</b><br />
                               { $posting/postingtext/text() }<br />
                               <a href="blog-complete/delete-posting/{string($posting/@postingdate)}">delete</a> | 
                               <a href="blog-complete/change-posting/{string($posting/@postingdate)}">change</a> | 
                               <a href="blog-complete/add-comment/{string($posting/@postingdate)}">add comment</a> | 
                               <a href="blog-complete/show-comments/{string($posting/@postingdate)}">
                               {fn:count($db/blog/postings/posting/comments/comment)} comment(s)</a></p>
                   return $r
          
  return
   <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{ $title }</title>
      <link rel="stylesheet" type="text/css" href="/style.css"/>
    </head>
    <body>
      <div class="right"><img src="/basex.svg" width="96"/></div>
      <h2>{ $title }</h2>

      <p><a href="blog-complete/change-settings">Add/Change my blog settings</a></p>

      <p><form method="post" action="blog-complete/new-posting">
        <p>Add new posting:</p>
        <table>
          <tr>
            <td>Titel:</td> <td><input name="new-postingtitle" size="50"></input></td>
          </tr>
          <tr>
            <td>Text:</td> <td><input name="new-postingtext" size="50"></input></td>
          </tr>
          <tr>
            <td></td> <td><input type="submit" /></td>
          </tr>
        </table>
      </form></p>

      { $postings }

      <p>Have a look at the <a href="blog-complete/show-blog-xml">xml source</a> of the blog.</p><br />

      <p><a href="blog-complete/drop-database">Drop blog database</a></p>
    </body>
  </html>
};

(:~
 : Creates a new blog database and redirects the user to the main page.
 :
 : The db:output function can be used to both perform updates and return results 
 : in a single query. It can only be used together with updating expressions. 
 : (For more details see: http://docs.basex.org/wiki/Database_Module#db:output)
 :)
declare %restxq:path("blog-complete/create-database")
        %restxq:GET
        updating function page:create-blog-database() {
          
  let $blogdb := <blog>
  <blogname>The Weather Blog</blogname>
  <blogauthor>
    <name>John Doe</name>
  </blogauthor>
  <postings>
  </postings>
</blog>
          
  (: Create the database and go to main page. :)
  return
    (db:output(page:redirect("/restxq/blog-complete")), 
     db:create("my-blog", $blogdb, "blog.xml"))
};

(:~
 : Deletes the blog database and redirects the user to the main page.
 :)
declare %restxq:path("blog-complete/drop-database")
        %restxq:GET
        updating function page:drop-blog-database() {
         
  (: Drop the database and go to main page. :)
  (db:output(page:redirect("/restxq/blog-complete")), 
   db:drop("my-blog"))
};

(:~
 : Creates a RESTXQ (HTTP) redirect header for the specified link.
 :
 : For more details see: http://docs.basex.org/wiki/RESTXQ#Response
 :
 : @param $redirect  page to forward to
 : @RETURN           redirect header
 :)
declare function page:redirect($redirect as xs:string) as element(restxq:response)
{
  <restxq:response>
    <http:response status="307">
      <http:header name="location" value="{ $redirect }"/>
    </http:response>
  </restxq:response>
};

(:~
 : Shows the blog database in xml format.
 :
 : @RETURN     the blog database in xml format
 :)
declare %restxq:path("blog-complete/show-blog-xml")
        function page:show-blog-xml() {
  <result>
    {let $db := db:open("my-blog") return $db}
  </result>
};

(:~
 : Adds a new posting to the blog database and redirects the user to the 
 : main page.
 :
 : @param     $postingtitle  the title of the new posting
 :            $postingtext   the text of the new posting
 :)
declare %restxq:path("blog-complete/new-posting")
        %restxq:POST
        %restxq:form-param("new-postingtitle","{$postingtitle}", "''")
        %restxq:form-param("new-postingtext","{$postingtext}", "''")
        updating function page:new-posting($postingtitle as xs:string, $postingtext as xs:string) {
  
  (: Open blog database. :)
  let $db := db:open("my-blog")
  
  (: Create posting node using current date/time as id. :)
  let $insert-node := <posting postingdate="{ current-dateTime() }">
                        <postingtitle>{ $postingtitle }</postingtitle>
                        <postingtext>{ $postingtext }</postingtext>
                        <comments/>
                      </posting>
                      
  return
    (db:output(page:redirect("/restxq/blog-complete")), 
     insert node $insert-node as first into $db/blog/postings)
};

(:~
 : Detetes the chosen posting from the blog database and redirects the 
 : user to the main page.
 :
 : @param     $id   the id of the posting to be deleted
 :)
declare %restxq:path("blog-complete/delete-posting/{$id}")
        %restxq:GET
        updating function page:delete-posting($id as xs:string) {
  
  (: Open blog database. :)
  let $db := db:open("my-blog")
  
  return
    (db:output(page:redirect("/restxq/blog-complete")), 
     delete node $db/blog/postings/posting[@postingdate=$id])
};

(:~
 : Offers the user the possibility to change the title and/or text of an
 : existing posting.
 :
 : @param     $id   the id of the posting to be changed
 :)
declare %restxq:path("blog-complete/change-posting/{$id}")
        %output:method("xhtml")
        %output:omit-xml-declaration("no")
        %output:doctype-public("-//W3C//DTD XHTML 1.0 Transitional//EN")
        %output:doctype-system("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")
  function page:change-posting($id as xs:string) {

  (: Open blog database. :)
  let $db := db:open("my-blog")
  
  (: Create page title using the user-specified name of the blog. :)
  let $blog := if (fn:string-length(fn:normalize-space($db/blog/blogname/text())) != 0) then
                 $db/blog/blogname/text()
               else
                 "Your blog"
  let $title := $blog || ' - Change posting'
  
  (: Get existing posting data to use them in the html form. :)
  let $posting := $db/blog/postings/posting[@postingdate=$id]
  let $postingtitle := $posting/postingtitle
  let $postingtext := $posting/postingtext

  return 
   <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{ $title }</title>
      <link rel="stylesheet" type="text/css" href="/style.css"/>
    </head>
    <body>
      <div class="right"><img src="/basex.svg" width="96"/></div>
      <h2>{ $title }</h2>
      
      <form method="post" action="replace-posting/{$id}">
        <p>Change the following posting:</p>
        <table>
          <tr>
            <td>Title:</td> <td><input name="new-postingtitle" size="50" value=" { $postingtitle } "></input></td>
          </tr>
          <tr>
            <td>Text:</td> <td><input name="new-postingtext" size="50" value=" { $postingtext } "></input></td>
          </tr>
          <tr>
            <td></td> <td><input type="submit" /></td>
          </tr>
        </table>
      </form>

      <p class='right'><a href='/restxq/blog-complete'>...back to main page</a></p>
    </body>
  </html>
};

(:~
 : Overwrites the title and text of the chosen posting in the blog database and 
 : redirects the user to the main page.
 :
 : @param     $id           the id of the posting to be changed
 :            $postingtitle the changed title of the posting
 :            $postingtext  the changed text of the posting
 :)
declare %restxq:path("blog-complete/change-posting/replace-posting/{$id}")
        %restxq:POST
        %restxq:form-param("new-postingtitle","{$postingtitle}", "''")
        %restxq:form-param("new-postingtext","{$postingtext}", "''")
        updating function page:replace-posting($id as xs:string, $postingtitle as xs:string, $postingtext as xs:string) {
          
  (: Open blog database. :)
  let $db := db:open("my-blog")
  
  (: Create new posting node which will replace the old one. :)
  let $title := <postingtitle>{ $postingtitle }</postingtitle>
  let $text := <postingtext>{ $postingtext }</postingtext>
  
  return
    (db:output(page:redirect("/restxq/blog-complete")), 
     replace node $db/blog/postings/posting[@postingdate=$id]/postingtitle with $title,
     replace node $db/blog/postings/posting[@postingdate=$id]/postingtext with $text)
};

(:~
 : Offers the user the possibility to change the blog's settings such as name of
 : the blog and name of the blog's author.
 :)
declare %restxq:path("blog-complete/change-settings")
        %output:method("xhtml")
        %output:omit-xml-declaration("no")
        %output:doctype-public("-//W3C//DTD XHTML 1.0 Transitional//EN")
        %output:doctype-system("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")
  function page:change-settings() {

  (: Open blog database. :)
  let $db := db:open("my-blog")
  
  (: Create page title using the user-specified name of the blog. :)
  let $blog := if (fn:string-length(fn:normalize-space($db/blog/blogname/text())) != 0) then
                 $db/blog/blogname/text()
               else
                 "Your new blog"
  let $title := $blog || ' - Add/Change settings'
  
  (: Get existing blog settings to use them in the html form. :)
  let $blogauthor := $db/blog/blogauthor/name
  let $blogname := $db/blog/blogname

  return 
   <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{ $title }</title>
      <link rel="stylesheet" type="text/css" href="/style.css"/>
    </head>
    <body>
      <div class="right"><img src="/basex.svg" width="96"/></div>
      <h2>{ $title }</h2>
      
      <form method="post" action="save-settings">
        <p>Add/change the following settings:</p>
        <table>
          <tr>
            <td>Blog author:</td> <td><input name="new-blogauthor" size="50" value=" {$blogauthor} "></input></td>
          </tr>
          <tr>
            <td>Blog name:</td> <td><input name="new-blogname" size="50" value=" {$blogname} "></input></td>
          </tr>
          <tr>
            <td></td> <td><input type="submit" /></td>
          </tr>
        </table>
      </form>

      <p class='right'><a href='/restxq/blog-complete'>...back to main page</a></p>
    </body>
  </html>
};

(:~
 : Overwrites the blog name and blog auther information in the blog database and 
 : redirects the user to the main page.
 :
 : @param     $blogname    the changed name of the blog
 :            $blogauthor  the changed author of the blog
 :)
declare %restxq:path("blog-complete/save-settings")
        %restxq:POST
        %restxq:form-param("new-blogname","{$blogname}", "''")
        %restxq:form-param("new-blogauthor","{$blogauthor}", "''")
        updating function page:save-settings($blogname as xs:string, $blogauthor as xs:string) {
  
  (: Open blog database. :)
  let $db := db:open("my-blog")
  
  (: Create new name and author nodes which will replace the old ones. :)
  let $replace-name := <blogname>{ $blogname }</blogname>
  let $replace-author := <blogauthor>
                           <name>{ $blogauthor }</name>
                         </blogauthor>
  return
    (db:output(page:redirect("/restxq/blog-complete")), 
     replace node $db/blog/blogname with $replace-name, 
     replace node $db/blog/blogauthor with $replace-author)
};

(:~
 : Offers the user the possibility to add a comment to the chosen posting.
 :
 : @param     $id           the id of the posting which to add the comment to
 :)
declare %restxq:path("blog-complete/add-comment/{$id}")
        %output:method("xhtml")
        %output:omit-xml-declaration("no")
        %output:doctype-public("-//W3C//DTD XHTML 1.0 Transitional//EN")
        %output:doctype-system("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")
  function page:add-comment($id as xs:string) {

  (: Open blog database. :)
  let $db := db:open("my-blog")
  
  (: Create page title using the user-specified name of the blog. :)
  let $blog := if (fn:string-length(fn:normalize-space($db/blog/blogname/text())) != 0) then
                 $db/blog/blogname/text()
               else
                 "Your blog"
  let $title := $blog || ' - Add comment'

  return 
   <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{ $title }</title>
      <link rel="stylesheet" type="text/css" href="/style.css"/>
    </head>
    <body>
      <div class="right"><img src="/basex.svg" width="96"/></div>
      <h2>{ $title }</h2>
      
      <form method="post" action="save-comment/{$id}">
        <p>Add the following comment:</p>
        <table>
          <tr>
            <td>Your name:</td> <td><input name="commentauthor" size="50"></input></td>
          </tr>
          <tr>
            <td>Your comment:</td> <td><input name="commenttext" size="50"></input></td>
          </tr>
          <tr>
            <td></td> <td><input type="submit" /></td>
          </tr>
        </table>
      </form>

      <p class='right'><a href='/restxq/blog-complete'>...back to main page</a></p>
    </body>
  </html>
};

(:~
 : Saves the new comment in the blog database and redirects the user to 
 : the main page.
 :
 : @param     $id            the id of the posting which to add the comment to
 :            $commentauthor the author of the comment
 :            $commenttext   the text of the comment
 :)
declare %restxq:path("blog-complete/add-comment/save-comment/{$id}")
        %restxq:POST
        %restxq:form-param("commentauthor","{$commentauthor}", "''")
        %restxq:form-param("commenttext","{$commenttext}", "''")
        updating function page:save-comment($id as xs:string, $commentauthor as xs:string, $commenttext as xs:string) {
  
  (: Open blog database. :)
  let $db := db:open("my-blog")
  
  (: Create a new comment node which will be added to the specified posting. :)
  let $comment := <comment commentdate="{ current-dateTime() }">
                    <commentauthor>{ $commentauthor }</commentauthor>
                    <commenttext>{ $commenttext }</commenttext>
                  </comment>
     
  return
    (db:output(page:redirect("/restxq/blog-complete")), 
     insert node $comment as first into $db/blog/postings/posting[@postingdate=$id]/comments)
};

(:~
 : Shows all comments belonging to the chosen posting.
 :
 : @param     $id           the id of the posting which the comment belongs to
 :)
declare %restxq:path("blog-complete/show-comments/{$id}")
        %output:method("xhtml")
        %output:omit-xml-declaration("no")
        %output:doctype-public("-//W3C//DTD XHTML 1.0 Transitional//EN")
        %output:doctype-system("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")
  function page:show-comments($id as xs:string) {

  (: Open blog database. :)
  let $db := db:open("my-blog")
  
  (: Create page title using the user-specified name of the blog. :)
  let $blog := if (fn:string-length(fn:normalize-space($db/blog/blogname/text())) != 0) then
                 $db/blog/blogname/text()
               else
                 "Your blog"
  let $title := $blog || ' - Comments'
  
  let $posting := $db/blog/postings/posting[@postingdate = $id]
  
  let $blogauthor := if (fn:string-length(fn:normalize-space($db/blog/blogauthor/name/text())) != 0) then
                       $db/blog/blogauthor/name/text()
                     else
                       "the blog's author"
  
  (: Format posting. :)
  let $poutput := <p><small>On {fn:substring(string($posting/@postingdate), 0, 11) || " at " || 
                     fn:substring(string($posting/@postingdate), 12, 5) || " " || $blogauthor } posted: </small><br />
                     <b>{ $posting/postingtitle/text() }</b><br />
                     { $posting/postingtext/text() }</p>
                     
  (: Collect and format the comments belonging to this posting. :)
  let $coutput := for $c in $posting/comments/comment
                  let $r := <p><small>On {fn:substring(string($c/@commentdate), 0, 11) || " at " || 
                               fn:substring(string($c/@commentdate), 12, 5) || " " || $c/commentauthor/text() } commented: </small><br />
                               { $c/commenttext/text() }</p>
                    return $r
  
  return
   <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{ $title }</title>
      <link rel="stylesheet" type="text/css" href="/style.css"/>
    </head>
    <body>
      <div class="right"><img src="/basex.svg" width="96"/></div>
      <h2>{ $title }</h2>

      { $poutput }
      
      <h3>Comments referring to this posting:</h3>
      
      { $coutput }

      <p class='right'><a href='/restxq/blog-complete'>...back to main page</a></p>
    </body>
  </html>
};