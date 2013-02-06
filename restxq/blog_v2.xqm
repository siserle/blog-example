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
 : @author BaseX Team
 :)
module namespace page = 'http://basex.org/modules/web-page';


(:~
 : The main page of the blog.
 :
 : If the blog database does not yet exist, the user must create one in order
 : to start working on the blog.
 :)
declare %restxq:path("blog-v2")
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

      <p>You have to <a href="/restxq/blog-v2/create-database">create the blog database</a> first.</p>
    </body>
  </html>
};


(:~
 : If the blog database does exist, the user can start to write postings.
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
                               <a href="/restxq/blog-v2/delete-posting/{string($posting/@postingdate)}">delete</a> | 
                               <a href="/restxq/blog-v2/change-posting/{string($posting/@postingdate)}">change</a></p>
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

      <p><form method="post" action="/restxq/blog-v2/new-posting">
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

      <p>Have a look at the <a href="/restxq/blog-v2/show-blog-xml">xml source</a> of the blog.</p><br />

      <p><a href="/restxq/blog-v2/drop-database">Drop blog database</a></p>
    </body>
  </html>
};

(:~
 : Creates a new blog database.
 :)
declare %restxq:path("blog-v2/create-database")
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
          
  (: Create the database. :)
  return
    db:create("my-blog", $blogdb, "blog.xml")
};

(:~
 : Deletes the blog database.
 :)
declare %restxq:path("blog-v2/drop-database")
        %restxq:GET
        updating function page:drop-blog-database() {
         
  (: Drop the database and go to main page. :)
  db:drop("my-blog")
};

(:~
 : Shows the blog database in xml format.
 :
 : @RETURN     the blog database in xml format
 :)
declare %restxq:path("blog-v2/show-blog-xml")
        function page:show-blog-xml() {
  <result>
    {let $db := db:open("my-blog") return $db}
  </result>
};

(:~
 : Adds a new posting to the blog database.
 :
 : @param     $postingtitle  the title of the new posting
 :            $postingtext   the text of the new posting
 :)
declare %restxq:path("blog-v2/new-posting")
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
    insert node $insert-node as first into $db/blog/postings
};

(:~
 : Detetes the chosen posting from the blog database.
 :
 : @param     $id   the id of the posting to be deleted
 :)
declare %restxq:path("blog-v2/delete-posting/{$id}")
        %restxq:GET
        updating function page:delete-posting($id as xs:string) {
  
  (: Open blog database. :)
  let $db := db:open("my-blog")
  
  return
    delete node $db/blog/postings/posting[@postingdate=$id]
};

(:~
 : Offers the user the possibility to change the title and/or text of an
 : existing posting.
 :
 : @param     $id   the id of the posting to be changed
 :)
declare %restxq:path("blog-v2/change-posting/{$id}")
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
      
      <form method="post" action="/restxq/blog-v2/change-posting/replace-posting/{$id}">
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

      <p class='right'><a href='/restxq/blog-v2'>...back to main page</a></p>
    </body>
  </html>
};

(:~
 : Overwrites the title and text of the chosen posting in the blog database.
 :
 : @param     $id           the id of the posting to be changed
 :            $postingtitle the changed title of the posting
 :            $postingtext  the changed text of the posting
 :)
declare %restxq:path("blog-v2/change-posting/replace-posting/{$id}")
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
    (replace node $db/blog/postings/posting[@postingdate=$id]/postingtitle with $title,
     replace node $db/blog/postings/posting[@postingdate=$id]/postingtext with $text)
};