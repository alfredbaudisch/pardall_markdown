# PardallMarkdown

[![Module Version](https://img.shields.io/hexpm/v/pardall_markdown.svg)](https://hex.pm/packages/pardall_markdown) [![Total Download](https://img.shields.io/hexpm/dt/pardall_markdown.svg)](https://hex.pm/packages/pardall_markdown) [![Last Updated](https://img.shields.io/github/last-commit/alfredbaudisch/pardall_markdown.svg)](https://github.com/alfredbaudisch/pardall_markdown/commits/master) [![Donate using PayPal](https://raw.githubusercontent.com/laurent22/joplin/dev/Assets/WebsiteAssets/images/badges/Donate-PayPal-green.svg)](https://www.paypal.com/donate?hosted_button_id=FC5FTRRE3548C) [![Become a patron](https://raw.githubusercontent.com/laurent22/joplin/dev/Assets/WebsiteAssets/images/badges/Patreon-Badge.svg)](https://www.patreon.com/alfredbaudisch)

## Table of Contents
- [Introduction](#introduction)
  - [Looking for Contributors ⚠️](#looking-for-contributors-%EF%B8%8F)
- [Video Demo and Tutorial](#video-demo-and-tutorial)
- [Features](#features)
  - [Use cases](#use-cases)
- [Usage in Elixir OTP applications](#usage-in-elixir-otp-applications)
  - [Usage with Phoenix applications](#usage-with-phoenix-applications)
- [API](#api)
  - [Models](#models)
- [Slug: unique identifiers for posts, pages, categories and trees](#slug-unique-identifiers-for-posts-pages-categories-and-trees)
- [Markdown file metadata and attributes](#markdown-file-metadata-and-attributes)
  - [Metadata parsers](#metadata-parsers)
    - [Elixir map](#elixir-map)
    - [Joplin notes](#joplin-notes)
    - [Custom parsers](#custom-parsers)
- [Taxonomy configuration with _index.md files](#taxonomy-configuration-with-_indexmd-files)
- [Posts and Pages](#posts-and-pages)
- [Content Hierarchies, Taxonomies, Categories and Sections](#content-hierarchies-taxonomies-categories-and-sections)
- [Trees](#trees)
  - [Taxonomy Tree](#taxonomy-tree)
  - [Content Trees](#content-trees)
  - [Post navigation](#post-navigation)
  - [Table of Contents](#table-of-contents-1)
- [Back pressure](#back-pressure)
- [FAQ](#faq)
  - [How to integrate it with Phoenix and Phoenix LiveView?](#how-to-integrate-it-with-phoenix-and-phoenix-liveview)
  - [PardallMarkdown vs static website generators (Hugo, Docusaurs, etc)](#pardallmarkdown-vs-static-website-generators-hugo-docusaurs-etc)
  - [PardallMarkdown vs NimblePublisher](#pardallmarkdown-vs-nimblepublisher)
  - [How to sync content with PardallMarkdown?](#how-to-sync-content-with-pardallmarkdown)
  - [How to write Markdown locally in your computer and publish it immediately to a PardallMarkdown application or website?](#how-to-write-markdown-locally-in-your-computer-and-publish-it-immediately-to-a-pardallmarkdown-application-or-website)
  - [Does it require a database?](#does-it-require-a-database)
  - [Why does it use Ecto?](#why-does-it-use-ecto)
- [Who's using?](#whos-using)
- [Roadmap](#roadmap)
- [Sponsors and Donations](#sponsors-and-donations)
- [Contributors](#contributors)
- [Copyright License](#copyright-license)
  - [Additional notices](#additional-notices)

## Introduction

PardallMarkdown is a reactive publishing framework and engine written in Elixir. Instant websites and documentation websites.

**As opposed to static website generators** (such as Hugo, Docusaurs and others), with PardallMarkdown, **you don't need to recompile and republish your application every time you write or modify new content**. The application can be kept running indefinitely in production, while it **watches a content folder for changes** and **the new content re-actively gets available for consumption** by your application.

The **content folder can be any path in the application server** or it can be a Git repository, since **PardallMarkdown has support for automatically pulling changes from a Git repository**.

### Looking for Contributors ⚠️
I'm looking for a contributor(s) to make a more elaborate HTML and CSS template for the demo project. Check the [current demo here](https://pardall.xyz/), including its inner sections. It's a mix of Blog + Documentation + Wiki website.

Something like [the Docusaurus template](https://docusaurus.io/docs) is perfect for this project. Docusaurus theme is MIT licensed, **so it can even be extracted to be used by PardallMarkdown**. But CSS is a thing that I'm not very fond of, so that's why I'm looking for help (**even if you could just extract Docusaurus theme as a static HTML template**, it would be awesome).

The current demo project and that HTML template have their [own repository](https://github.com/alfredbaudisch/pardall-markdown-phoenix-demo). So, you don't even need to know Elixir, just HTML and CSS. Any help will be appreciated!

## Video Demo and Tutorial
See PardallMarkdown in action and learn how to use it by following this video:
[![](https://github.com/alfredbaudisch/pardall_markdown/blob/master/priv/images/pardallmarkdown-demo-and-tutorial-with-play.jpg)](https://www.youtube.com/watch?v=FdzqToe3dug)

## Features

- Filesystem-based, with **Markdown** and static files support.
    - Markdown files are parsed as HTML.
- `FileWatcher`, that **detects new content and modification of existing content**, which then **automatically re-parses and rebuilds the content**.
    - There is **no need to recompile** and redeploy the application nor the website, the **new content is available immediately** (depends on the interval set via `:recheck_pending_file_events_interval`, see below).
    - Created with [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) and Phoenix Channels in mind: **create or modify a post** or a whole new **set of posts** and they are **immediately published in a website**. Check out [the demo](https://github.com/alfredbaudisch/pardall-markdown-phoenix-demo) repository.
- Support for content folders outside of the application, this way, **new content files can be synced immediately from a source location** (for example, your computer), and then picked up by the FileWatcher.
- `RepositoryWatcher`, that **detects changes from a Git repository** (optional) and automatically pulls the content into a PardallMarkdown's content folder.
  - Since the content folder is watched by `FileWatcher`, PardallMarkdown then rebuilds the whole content everytime there are changes from the Git repository.
- Automatic creation of **table of contents** from Markdown headers.
- **Infinite content hierarchies** (categories and sub-categories, sections and sub-sections).
    - Different **sets of custom hierarchies** and post sets. For example, a website with *Documentation*, *Blog*, *News* and a *Wiki*, which in turn, have their own sub-hierarchies.
    - **Custom sorting rules** per hierarchy set. For example, posts in the *Documentation* hierarchy can be sorted by priority, *Blog* posts by date and *Wiki* posts by title.
- Automatic creation of **taxonomy trees and content tress**.
    - Separate content trees, per root hierarchy are also created. For example, a content tree for the *Documentation* hierarchy, which contains links to all sub-hierarchies and posts.
- Automatic creation of **post navigation links** (next and previous posts).
- Freely embeddable **metadata into posts**, with the option to choose a parser (or a custom one) for the metadata (Elixir map, Joplin notes, YAML FrontMatter, etc).
- Hierarchy **archive lists**.
- All the content and indexes are kept in an **in-memory cache (Elixir's ETS)**.

### Use cases
- Blogs
- Documentation websites
- Wikis
- FAQs
- Any kind of website actually? Even e-commerce websites, where you can use PardallMarkdown's parsed content as product pages, and more.
- Any application that needs content?


## Usage in Elixir OTP applications
Add dependency and application into your `mix.exs`:
```elixir
defp deps do
  [{:pardall_markdown, "~> 0.4"} ...]
end

def application do
  [extra_applications: [:pardall_markdown, ...], ...]
end
```

Add the configuration (all keys are required) into `config.exs` or in any of the environment specific configuration files:

```elixir
config :pardall_markdown, PardallMarkdown.Content,
  # Where all of the uncompiled assets and content will live on
  # (the Markdown files and any static asset). In this path
  # you will create and update content.
  #
  # This can be any relative or absolute path,
  # including outside of the application, examples:
  # "/home/documents/content", "./content", "../path/to/content"
  root_path: "/home/documents/content",

  # The path that contains static assets,
  # those files won't be parsed.
  static_assets_path: "/home/documents/content/static",

  # ETS tables names
  cache_name: :content_cache,  
  index_cache_name: :content_index_cache,

  # How often in ms the FileWatcher should check for
  # new or modified content in the `root_path:`?
  recheck_pending_file_events_interval: 5_000,

  # Git repository to watch and automatically fetch content from,
  # leave "" or nil to not get content from a repository.
  #
  # The repository is cloned into `:remote_repository_local_path`.
  #
  # By not setting a repository URL, you have to fill and modify
  # content into the `:root_path` by other means (even manually).
  remote_repository_url: "",

  # Where to clone the repository? Must be the same as :root_path or the parent path of :root_path.
  # Example 1 - parent path of :root_path:
  # - `root_path`: "/content/markdown"
  # - `remote_repository_local_path`: "/content"
  #
  # Example 2 - the same as :root_path:
  # - `root_path`: "/content"
  # - `remote_repository_local_path`: "/content"
  remote_repository_local_path: "/home/documents/content",

  # How often in ms the RepositoryWatcher should pool
  # the `:remote_repository_url` Git repository and `fetch` changes?
  #
  # If `:remote_repository_url` is provided,
  # `:recheck_pending_remote_events_interval` must
  # be BIGGER than `:recheck_pending_file_events_interval`
  recheck_pending_remote_events_interval: 15_000

  # Should the main content tree contain a link to the Home/Root page ("/")?
  content_tree_display_home: false,

  # Should internal <a href/> links be converted to `Phoenix.LiveView` links?
  # If you are using PardallMarkdown with a `Phoenix.LiveView` application, you
  # definitely want this as `true`.
  convert_internal_links_to_live_links: true,

  # Markdown files can contain a top section with metadata/attributes related
  # to the file. Is the metadata required?
  is_markdown_metadata_required: true,

  # Are posts set as draft (unpublished) by default? If true, posts will appear
  # in the content trees only when they have the attribute `published: true`
  # (which sets `Post.is_published == true`). Draft posts can be retrieved
  # only by calling their slug directly with `Repository.get_by_slug/1`
  is_content_draft_by_default: true,

  # Which parser to use to parse a Markdown file's metadata?
  # See the documentation section *Markdown file metadata and attributes*
  metadata_parser: PardallMarkdown.MetadataParser.ElixirMap,

  # Callback to be called every time the content and the indexes are rebuilt.
  #
  # For example, you can put a reference to a function that calls Endpoint.broadcast!:
  # notify_content_reloaded: &MyPhoenixApp.content_reloaded/0
  #
  # Definition:
  # def content_reloaded do
  #   Application.ensure_all_started(:my_phoenix_app) # Recommended
  #   MyPhoenixApp.Endpoint.broadcast!("pardall_markdown_web", "content_reloaded", :all)
  # end
  notify_content_reloaded: &MyApp.content_reloaded/0
```

### Usage with Phoenix applications
Alongside the main required configuration, if you want to serve static files, add a `Plug.Static` into your `Phoenix.Endpoint` configuration that refers to the static assets folder (`:static_assets_path`):

```elixir
plug Plug.Static,
    at: "/static/", # if the static assets path ends at "/static", i.e. /path/to/content/static
    from: Content.Utils.static_assets_path(),
    gzip: true
```

Check [the demo](https://github.com/alfredbaudisch/pardall-markdown-phoenix-demo) application for a complete Phoenix application sample, including sample content. Or watch the PardallMarkdown Phoenix LiveView [tutorial video](https://www.youtube.com/watch?v=FdzqToe3dug).

## API
Content is retrieved with `PardallMarkdown.Repository`. Check details and instructions [in the docs](https://hexdocs.pm/pardall_markdown/PardallMarkdown.Repository.html).

```elixir
def get_all_posts(type \\ :all)
def get_all_links(type \\ :all)
def get_taxonomy_tree()
def get_content_tree(slug \\ "/")
def get_all_published()
def get_by_slug(slug)
def get_by_slug!(slug)
```

### Models
The content returned by the API is of the types:

- `PardallMarkdown.Content.Post` ([docs](https://hexdocs.pm/pardall_markdown/PardallMarkdown.Content.Post.html))
- `PardallMarkdown.Content.Link` ([docs](https://hexdocs.pm/pardall_markdown/PardallMarkdown.Content.Link.html))
- `PardallMarkdown.Content.AnchorLink` ([docs](https://hexdocs.pm/pardall_markdown/PardallMarkdown.Content.AnchorLink.html))

## Slug: unique identifiers for posts, pages, categories and trees
Every piece of content has an unique identifier, which is simply the content URL slug, example: `"/blog"`, `"/docs/getting-started/how-to-install`. Slugs always have a prepended slash, but never a trail slash.

The slug is used to get content in all forms using `PardallMarkdown.Repository` functions: individual pieces of content, trees and archives. The slug is also how the content is identified in cache.

Slugs are automatically generated from file paths. For example, a Markdown file named: `"/blog/news/Top news of_today.md"` will have the slug: `"/blog/news/top-news-of-today"`.

## Markdown file metadata and attributes
Markdown files may include post metadata / attributes / configuration at the top, which follows the same purpose as [Front Matter](https://jekyllrb.com/docs/front-matter/).

The metadata must follow the pattern and specs of the chosen `PardallMarkdown.MetadataParser` parser for the application. The parser is defined with the configuration key `:metadata_parser`.

By default, the metadata is required, but it can be made optional by the configuration `:is_markdown_metadata_required`.

The following configuration properties are available (all optional):
- `title`: the post title. If not provided, a title will be generated from the post slug.
- `date`: the date or date-time to be considered for the post, string, ISO format. If not provided, the file modification date will be considered as the post date.
- `published`: a post without `published: true` set will be considered draft. The default can be inverted when the configuration `:is_content_draft_by_default` is set to `false`, this way, posts will always be considered as published, unless they contain: `published: false`.
- `summary`: post description or short content. If `summary` is not provided, a summary will be generated from the Post's content/body.
- `position`: if the post topmost taxonomy has a `:sort_by` rule set to `:position`, this is the value that will be used to sort the post (see below).
- `slug`: override the post slug. As seem above, by default, slugs are generated from the file names and are the main, unique identifier of posts.
  - If you override the slug with this property, make sure to put the full path, prepended by a slash, example: `slug: "/my/custom/slug"`.
  - It's your responsibility to put non-conflicting slugs when overriding slugs with this property.
- Any other extra property, which will be saved into the post's `PardallMarkdown.Content.Post.metadata` field.

### Metadata parsers
#### Elixir map
The metadata is defined with an Elixir Map, separated by `---` and a line break. The properties are Map keys as atoms.

Example:
```elixir
%{
    title: "PardallMarkdown public release",
    date: "2021-09-11", # or "2021-09-11T14:40:00Z"
    published: true,
    summary: "This post announces the launch of the project",
    position: 0,
    my_custom_data: :used_by_my_custom_application
}
---
Content goes here
```

If you want to use automatic values, the map can be empty (or you can leave out the map when `is_markdown_metadata_required: false`):
```elixir
%{
}
---
Content goes here
```

#### Joplin notes
Markdown posts exported from [Joplin](https://joplinapp.org/) notes always contain the title of the post at the top, separated by a blank line, example:

```
Post title

... content goes here
```

The parser `PardallMarkdown.MetadataParser.JoplinNote` is available to deal with Joplin notes. Note that you can also add metadata to Joplin notes, even inside Joplin. The metadata format has to be in a chosen parser and then you just add it at the top of the note in Joplin itself, example:

Note title: "Post title"

```
%{
  position: 0
}
---
Content goes here.
```

Joplin will export it as:
```
Post title

%{
  position: 0
}
---
Content goes here.
```

You can use any metadata parser for Joplin notes (by default, elixir maps with `PardallMarkdown.MetadataParser.ElixirMap`) with the configuration:

```
config :pardall_markdown, PardallMarkdown.MetadataParser.JoplinNote,
  metadata_parser_after_title: PardallMarkdown.MetadataParser.ElixirMap
```

#### Custom parsers
To implement a parser, check the behaviour `PardallMarkdown.MetadataParser` and the existing included parsers (in `/lib/pardall_markdown/metadata_parser/`).

## Taxonomy configuration with _index.md files
Inside top level taxonomies, a `_index.md` can be created which can contain taxonomy configuration (via a metadata map) as well an optional `PardallMarkdown.Content.Post` content for the taxonomy archive page, the contents of this file are saved into `PardallMarkdown.Content.Link.index_post`.

The `_index` metadata map may contain:

- `:title`: override taxonomy title/name.
- `:sort_by`: children posts sorting rules (for all posts inside all levels down inside this taxonomy). Accepted values: `:title | :date | :position`.
- `:sort_order`: accepted values: `:desc | :asc`.
- Any other extra property, which will be saved into the taxonomy's `PardallMarkdown.Content.Link.index_post.metadata` field.

Notice that `_index` files are not available via a slug call, i.e. `"/taxonomy/-index"`, instead you must get the taxonomy slug and access the file and post data via `PardallMarkdown.Content.Link.index_post`.

## Posts and Pages
Every Markdown file is a post (a piece of content), but PardallMarkdown considers a file in the root folder `"/"` as a "page" and files inside any folder, at any hierarchy level, a "post". Pages are added to the content tree side by side with root hierarchies.

Structurally they are the same, the only difference is their property is set to `PardallMarkdown.Content.Post.type: :post | :page`.

Examples:
- Pages: single unique posts that can refer to fixed data, such as a Contact or About page (/contact, /about, etc).
- Posts: every other piece of content, including blog posts, documentation pages, wiki pages, so on and so forth, which are inside at least one level of taxonomy, example: `"/docs/introduction"` or `"/wiki/languages/english/verbs/to-eat"`.

## Content Hierarchies, Taxonomies, Categories and Sections
Categories, Taxonomies and Website Sections all refer to the same thing: the hierarchy of folders in which the posts are contained in, which in turn define post sets or group of posts. 

- A taxonomy/category/section/group name comes from the folder name, where each word is capitalized.
- Hierarchies are defined from nested folders. 
- A top level taxonomy is a first level folder, example: `"/blog"`, hence the example `"/blog/news/art"` has `"/blog"` as its top level taxonomy/parent.
- Posts are saved individually (to be retrieved with `PardallMarkdown.Repository.get_by_slug("/a/post/slug")`) and under their taxonomies and taxonomies' hierarchy. A taxonomy archive (all posts of a taxonomy) and its hierarchy are contained in `PardallMarkdown.Content.Link.children` when the taxonomy is retrieved by:
    - `PardallMarkdown.Repository.get_by_slug("/taxonomy/inner-taxonomy")`
    - `PardallMarkdown.Repository.get_content_tree("/taxonomy/inner-taxonomy")`
    - `PardallMarkdown.Repository.get_content_tree("/")` - root, which contains all taxonomies, their posts and hierarchy.
- **When retrieving a taxonomy by slug** with `PardallMarkdown.Repository.get_by_slug("/taxonomy/inner-taxonomy")` the taxonomy `:children` contains all posts from all of its innermost taxonomies `:children`.
    - For example, the post: "/blog/news/city/foo" appears inside the `:children` of 3 taxonomies: `"/blog"`, `"/blog/news"` and `"/blog/news/city"`.
- On the other hand, **taxonomies in the content tree** retrieved with `PardallMarkdown.Repository.get_content_tree/1` contains only their immediate children posts.
    - For example, the post: "/blog/news/city/foo" appears only inside the `:children` of its defining taxonomy: `"/blog/news/city"`.

Consider the example content directory structure:
```
content/
|   about.md
|   contact.md
└───blog/
|   |   _index.md
|   |   post1.md
|   |   post2.md
|   └───art/
|   |   └───traditional/
|   |       └───oil-paintings/
|   |           └───impressionism/
|   |               └───claude-monet/
|   |               └───pierre-auguste-renoir/
|   └───news/
|       |   .. posts..
|       └───city/
|       |   |   ..posts..
|       └───worldwide/
|           |   ..posts..
└───docs/
|   |   _index.md
|   |   getting-started.md
|   └───setup/
| ...more and more...
```

Also, consider that the `docs/_index.md`, defines a `:title` for the `docs` folder, which will override the default naming convention.

The following categories will be created:
```
["Blog"]
["Blog"]["Art]
["Blog"]["Art]["Traditional"]
["Blog"]["Art]["Traditional"]["Oil Paintings"]
["Blog"]["Art]["Traditional"]["Oil Paintings"]["Impressionism"]
["Blog"]["Art]["Traditional"]["Oil Paintings"]["Impressionism"]["Claude Monet"]
["Blog"]["Art]["Traditional"]["Oil Paintings"]["Impressionism"]["Pierre Auguste Renoir"]
["Blog"]["News"]
["Blog"]["News"]["City]
["Blog"]["News"]["Worldwide]
["Documentation"]
["Documentation"]["Setup]
```

## Trees
Three types of trees are generated every time the content is recompiled.

Those trees can be used to navigate content, can be printed as a list of links, etc. Check the [demo project](https://github.com/alfredbaudisch/pardall-markdown-phoenix-demo) for multiple examples of how to use the trees and HTML helpers to generate links from the trees.

The trees are:

### Taxonomy Tree
A tree with all the taxonomies, sorted by title, and nested accordingly.

The taxonomy tree can be retrieved via `PardallMarkdown.Repository.get_taxonomy_tree/0`.

### Content Trees
A tree containing all the taxonomies, but with their children posts nested:

- Posts are placed below their innermost taxonomy.
- Posts are sorted by their topmost taxonomy sorting rules.

Multiple content trees are created. A single "master" content tree, available by the root slug `"/"` and a content tree for each taxonomy level. For example, a content tree for the *Documentation* hierarchy, which contains links to all sub-hierarchies and posts.

Content trees can be retrieved via `PardallMarkdown.Repository.get_content_tree/1`.

### Post navigation
Inside all posts is inserted a link the the previous and the next posts in the tree, after the current post. The links are in `PardallMarkdown.Content.Post.link.previous` and `PardallMarkdown.Content.Post.link.next`.

### Table of Contents
Each post contain their own automatically generated Table of Contents tree, available inside the post's `PardallMarkdown.Content.Post.toc` field.

## Back pressure
TODO: describe `FileWatcher` back pressure mechanism.

## FAQ
### How to integrate it with Phoenix and Phoenix LiveView?
There is a demo project in a separate repository: [PardallMarkdown Phoenix Demo](https://github.com/alfredbaudisch/pardall-markdown-phoenix-demo).

The demo project also has HTML helpers to print the generated tables of contents, taxonomy and hierarchy trees as HTML `<ul/>` lists with `<a/>` links.

### PardallMarkdown vs static website generators (Hugo, Docusaurs, etc)
Every time you make a change to the content or add new content, static website generators require you to rebuild and republish the whole application.

As seen in the Introduction, with PardallMarkdown the application can be kept running indefinitely in production, and **the new content re-actively gets available for consumption** by your application.

### PardallMarkdown vs NimblePublisher
[NimblePublisher](https://github.com/dashbitco/nimble_publisher) is an Elixir framework that parses Markdown files at compile time and make them available all at once in an Elixir's module attribute.

If you need to modify or write new content, you have to recompile and republish the application. That's the only feature provided by NimblePublisher.

If you intend to have a plain blog page, with few posts, without hierarchies, taxonomies, categories, sorting and navigation, NimblePublisher is more than enough, and PardallMarkdown may be overkill for you.

By the way, the idea of adding an Elixir map with metadata inside Markdown files and the code to parse it comes from a piece of code from NimblePublisher's code (inside `PardallMarkdown.FileParser.parse_contents`).

### How to sync content with PardallMarkdown?
PardallMarkdown watches for changes from a given content folder (configured via `:root_path`), but there's nothing special about the content folder. Just add and sync content to the content folder normally.

The folder contents can be changed manually or via a Git repository.

PardallMarkdown has support to watch a Git repository (configured via `:remote_repository_url`), repository changes are fetched automatically, and PardallMarkdown rebuilds the contents also automagically. The [Phoenix demo project](https://github.com/alfredbaudisch/pardall_markdown_phoenix_demo) fetches content from [PardallMarkdown's Sample Content repository](https://github.com/alfredbaudisch/pardall_markdown_sample_content), so you can see how it works. 

### How to write Markdown locally in your computer and publish it immediately to a PardallMarkdown application or website?
As written above, PardallMarkdown watches for changes in a folder. This way, you can sync content from a local source to a remote destination via any way as you would do with or without PardallMarkdown, for example: Git, SyncThings, scp, etc.

Example:

- Create a folder in your computer
- Create a folder in the server that will run your PardallMarkdown powered application
- Install and configure [SyncThings](https://github.com/syncthing/syncthing) to sync between the two machines
- Start your PardallMarkdown server application in the remote location
- Start SyncThings
- Write locally and see the magic happens! Content appears almost immediately in your application / website.

If you don't want to use SyncThings, you can have a custom Git repository just for the content and configure PardallMarkdown to watch for changes from this repository with `:remote_repository_url`. Check [Usage in Elixir OTP applications](#usage-in-elixir-otp-applications) and [How to sync content with PardallMarkdown?](#how-to-sync-content-with-pardallmarkdown) above.

### Does it require a database?
No.

### Why does it use Ecto?
- Being used for Post validation and a lot of `embedded_schemas` and the power of `cast_embed`.
- If needed, an optional database layer may be added in the future.

## Who's using?
- [Pardall](https://pardall.xyz/): this is [my own](https://pardall.xyz/about) [Wiki](https://pardall.xyz/wiki), which serves as a proof of concept for a website made with PardallMarkdown and Phoenix.LiveView, with Markdown files created from Joplin notes. The content for the Wiki is automatically synced from the [alfredbaudisch/pardall.xyz_content](https://github.com/alfredbaudisch/pardall.xyz_content) repository.

## Roadmap
- [x] Add support for custom metadata parsers ([#30](https://github.com/alfredbaudisch/pardall_markdown/issues/30)).
- [x] Add support for Joplin Notes ([#32](https://github.com/alfredbaudisch/pardall_markdown/issues/32)).
- [ ] Add support for content folders inside a S3 bucket, which will then notify a PardallMarkdown application with webhooks.
- [x] Add support to watch external sources for new content, such as Git repositories ([#31](https://github.com/alfredbaudisch/pardall_markdown/issues/31)).
- [ ] Add support for FrontMatter post metadata with YAML ([#41](https://github.com/alfredbaudisch/pardall_markdown/issues/41)).

## Sponsors and Donations

You can support my open-source contributions and this project on [Patreon](https://www.patreon.com/alfredbaudisch) or with a [PayPal donation](https://www.paypal.com/donate?hosted_button_id=FC5FTRRE3548C). Patrons and donors of any tier will have their name listed here. Patrons of the **Sponsors** tier or higher, can also have a link and a logo listed here.

- Mike King

## Contributors

- [Alfred Reinold Baudisch](https://github.com/alfredbaudisch/): PardallMarkdown creator and maintainer.
- [Cody Brunner](https://github.com/rockchalkwushock): added the initial implementation to remote content support via automatic Git repository pooling and fetching - `RepositoryWatcher` ([#31](https://github.com/alfredbaudisch/pardall_markdown/issues/31)).

## Copyright License

    Copyright 2021 Alfred Reinold Baudisch (alfredbaudisch, pardall)

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

### Additional notices

- It's suggested that applications using this software mention this project name with a link to this project repository. You can put it anywhere in your application, for example, in a website footer or *About* page: `Powered by [PardallMarkdown](https://github.com/alfredbaudisch/pardall_markdown)`.
- PardallMarkdown uses some snippets of code from the following projects:
  - [nimble_publisher](https://github.com/dashbitco/nimble_publisher), Copyright 2020 Dashbit, licensed under Apache License, Version 2.0.
  - [blogit](https://github.com/meddle0x53/blogit), Copyright (c) 2017 Nikolay Tsvetinov (Meddle), licensed under The MIT License (MIT).
