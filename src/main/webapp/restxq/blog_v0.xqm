(:~
 : This module contains a basic blog example demonstrating how to develop
 : a simpl RESTXQ web applications with BaseX.
 :
 : Version 0 shows:
 : - the basics of RESTXQ annotations
 : - how to create html output
 :
 : - how to create and drop a database (For more details see
 :   http://docs.basex.org/wiki/Database_Module)
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
declare %restxq:path("blog-v0")
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

      <p>You have to <a href="blog-v0/create-database">create the blog database</a> first.</p>
    </body>
  </html>
};


(:~
 : If the blog database does exist, the user can start to edit the blog.
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
  (:let $postings := for $posting in $db/blog/postings/posting
                   let $r := <p><small>On {fn:substring(string($posting/@postingdate), 0, 11) || " at " || 
                                fn:substring(string($posting/@postingdate), 12, 5) || " " || $author } posted: </small><br />
                               <b>{ $posting/postingtitle/text() }</b><br />
                               { $posting/postingtext/text() }<br />
                               <a href="blog-v0/delete-posting/{string($posting/@postingdate)}">delete</a> | 
                               <a href="blog-v0/change-posting/{string($posting/@postingdate)}">change</a> | 
                               <a href="blog-v0/add-comment/{string($posting/@postingdate)}">add comment</a> | 
                               <a href="blog-v0/show-comments/{string($posting/@postingdate)}">
                               {fn:count($db/blog/postings/posting/comments/comment)} comment(s)</a></p>
                   return $r:)
          
  return
   <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{ $title }</title>
      <link rel="stylesheet" type="text/css" href="/style.css"/>
    </head>
    <body>
      <div class="right"><img src="/basex.svg" width="96"/></div>
      <h2>{ $title }</h2>

      <p>Have a look at the <a href="blog-v0/show-blog-xml">xml source</a> of the blog.</p><br />

      <p><a href="blog-v0/drop-database">Drop blog database</a></p>
    </body>
  </html>
};

(:~
 : Creates a new blog database.
 :)
declare %restxq:path("blog-v0/create-database")
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
declare %restxq:path("blog-v0/drop-database")
        %restxq:GET
        updating function page:drop-blog-database() {
         
  (: Drop the database. :)
  db:drop("my-blog")
};

(:~
 : Shows the blog database in xml format.
 :
 : @RETURN     the blog database in xml format
 :)
declare %restxq:path("blog-v0/show-blog-xml")
        function page:show-blog-xml() {
  <result>
    {let $db := db:open("my-blog") return $db}
  </result>
};