# PardallMarkdown

[![Module Version](https://img.shields.io/hexpm/v/pardall_markdown.svg)](https://hex.pm/packages/pardall_markdown)
[![Total Download](https://img.shields.io/hexpm/dt/pardall_markdown.svg)](https://hex.pm/packages/pardall_markdown)
[![License](https://img.shields.io/hexpm/l/pardall_markdown.svg)](https://github.com/alfredbaudisch/pardall_markdown/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/alfredbaudisch/pardall_markdown.svg)](https://github.com/alfredbaudisch/pardall_markdown/commits/master)

PardallMarkdown is a reactive publishing framework and engine written in Elixir. Instant websites and documentation websites.

**As opposed to static website generators** (such as Hugo, Docusaurs and others), with PardallMarkdown, **you don't need to recompile and republish your application everytime you write or modify new content**. The application can be kept running indefinitely in production, and **the new content reactively gets available for consumption** by your application.

## Features

- Filesystem-based, with **Markdown** and static files support.
    - Markdown files are parsed as HTML.
- FileWatcher, that **detects new content and modification of existing content**, which then **automatically reparses and rebuilds the content**.
    - There is **no need to recompile** and redeploy the application nor the website, the **new content is available immediately** (depends on the interval set via `:recheck_pending_file_events_interval`, see below).
    - Created with [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) and Phoenix Channels in mind: **create or modify a post** or a whole new **set of posts** and they are **immediately published in a website**. Check out [the demo](https://github.com/alfredbaudisch/pardall-markdown-phoenix-demo) repository.
- Support for the content folders outside of the application, this way, **new content files can be synced immediately from a source location** (for example, your computer), and then picked up by the FileWatcher.
- Automatic creation of **table of contents** from Markdown headers.
- **Infinite content hierarchies** (categories and sub-categories, sections and sub-sections).
    - Different **sets of custom hierarchies** and post sets. For example, a website with *Documentation*, *Blog*, *News* and a *Wiki*, which in turn, have their own sub-hierarchies.
    - **Custom sorting rules** per hierarchy set. For example, posts in the *Documentation* hierarchy can be sorted by priority, *Blog* posts by date and *Wiki* posts by title.
- Automatic creation of **taxonomy trees and content tress**.
    - Separate content trees, per root hierarchy are also created. For example, a content tree for the *Documentation* hierarchy, which contains links to all sub-hierarchies and posts.
- Automatic creation of **post navigation links** (next and previous posts).
- Freely embeddable **metadata into posts** as Elixir maps.
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
[{:pardall_markdown, "~> 0.1.0"} ...]
end

def application do
[applications: [:pardall_markdown, ...], ...]
end
```

Add the configuration (all keys are required) into `config.exs` or in any of the enviroment specific configuration files:

```elixir
config :pardall_markdown, PardallMarkdown.Content,
  # Where all of the uncompiled assets and content will live on
  # (the Markdown files and any static asset). In this path
  # you will create and update content.
  #
  # This can be any relative or absolute path,
  # including outside of the application.
  root_path: "/home/documents/content",

  # Name of the folder inside `root_path:`, that contains static assets,
  # those files won't be parsed.
  static_assets_folder_name: "static",

  # ETS tables names
  cache_name: :content_cache,  
  index_cache_name: :content_index_cache,

  # Site name to be appened into page titles, after the post or page title
  site_name: "Pardall Markdown",

  # How often in ms the FileWatcher should check for
  # new or modified content in the `root_path:`?
  recheck_pending_file_events_interval: 10_000,

  # Should the main content tree contain a link to the Home/Root page ("/")?
  content_tree_display_home: false,

  # Callback to be called everytime the content and the indexes are rebuilt.
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

## Models

- `PardallMarkdown.Post` ([docs](https://hexdocs.pm/pardall_markdown/PardallMarkdown.Post.html))
- `PardallMarkdown.Link` ([docs](https://hexdocs.pm/pardall_markdown/PardallMarkdown.Link.html))
- `PardallMarkdown.ContentLink` ([docs](https://hexdocs.pm/pardall_markdown/PardallMarkdown.ContentLink.html))

## API
Content is retrieved with `PardallMarkdown.Content.Repository`. Check details and instructions [in the docs](https://hexdocs.pm/pardall_markdown/PardallMarkdown.Content.Repository.html).

```elixir
def get_all_posts(type \\ :all)
def get_all_links(type \\ :all)
def get_taxonomy_tree()
def get_content_tree(slug \\ "/")
def get_all_published
def get_by_slug(slug)
def get_by_slug!(slug)
```

## Metadata map / how to write content
- Published: true

## Slug: unique identifiers for posts, pages, categories and trees
Every piece of content has an unique identifier, which is simply the content URL slug, example: `"/blog"`, `"/docs/getting-started/how-to-install`. The slugs always have a prepended slash, but never a trail slash.

The slug is used to get content in all forms using PardallMarkdown functions: individual pieces of content, trees and archives.

## Trees

## Configuration _index files
Sorting rules

## Posts and Pages

## Archives
- Show inner posts inside outside categories

## Content Hierarchies, Categories and Sections
Categories (or Sections) are created from folder names. Hierarchies are defined from nested folders. A category name comes from the folder name, where each word is capitalized.

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

# FAQ
## How to integrate it with Phoenix and Phoenix LiveView?
There is a demo project in a separate repository: [PardallMarkdown Phoenix Demo](https://github.com/alfredbaudisch/pardall-markdown-phoenix-demo).

The demo project also has HTML helpers to print the generated tables of contentes, taxonomy and hierarchy trees as HTML `<ul/>>` lists with `<a/>` links.

## PardallMarkdown vs static website generators (Hugo, Docusaurs, etc)
Every time you make a change to the content or add new content, static website generators require you to rebuild and republish the whole application.

As seen in the Introduction, with PardallMarkdown the application can be kept running indefinitely in production, and **the new content reactively gets available for consumption** by your application.

## PardallMarkdown vs NimblePublisher
[NimblePublisher](https://github.com/dashbitco/nimble_publisher) is an Elixir framework that parses Markdown files at compile time and make them available all at once in an Elixir's module attribute.

If you need to modify or write new content, you have to recompile and republish the application. That's the only feature provided by NimblePublisher.

If you intend to have a plain blog page, with few posts, without hierarchies, taxonomies, categories, sorting and navigation, NimblePublisher is more than enough, and PardallMarkdown may be overkill for you.

By the way, the idea of adding an Elixir map with metadata inside Markdown files and the code to parse it comes from a piece of code from NimblePublisher's code (inside `PardallMarkdown.Content.FileParser.parse_contents`).

## How to sync content to PardallMarkdown?
PardallMarkdown watches for changes from a given content folder (configured via `:root_path`), but there's nothing special about the content folder. Just add and sync content to the content folder normally.

## How to write Markdown locally in your computer and publish it immediately to a PardallMarkdown application or website?
As written above, PardallMarkdown watches for changes in a folder. This way, you can sync content from a local source to a remote destination via any way as you would do with or without PardallMarkdown, for example: Git, SyncThings, scp, etc.

Example:

- Create a folder in your computer
- Create a folder in the server that will run your PardallMarkdown powered application
- Install and configure [SyncThings](https://github.com/syncthing/syncthing) to sync between the two machines
- Start your PardallMarkdown server application in the remote location
- Start SyncThings
- Write locally and see the magic happens! Content appears almost immediately in your application / website.

If you don't want to use SyncThings, you can have a custom Git repository just for the content and a hook that mirrors the content to a folder watched by your PardallMarkdown configuration.

## Does it require a database?
No.

## Why does it use Ecto?
- Being used for Post validation and a lot of `embedded_schemas` and the power of `cast_embed`.
- If needed, an optional database layer may be added in the future.

## Writing locally

# WIP ------- STILL PUBLISHING PACKAGE AND NO README AND NO DOCS WRITTEN YET!

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.setup`
- Install Node.js dependencies with `npm install` inside the `assets` directory
- Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix

# Stuff to add here
- Table of contents
- Custom sorting by top level slug
- Explain terms (taxonomies, categories, etc)
- Content setup
- Content view helpers
- Post Navigation
- Infinitely nestable categories

## Taxonomy and Content Trees
- Root and per top level slug


# TODO: Licenses
- Dashbit Nimblepublisher
- This project's license

Filewatcher backpressure