# WIP: Build a reactive real-time Markdown-based website with Phoenix LiveView and PardallMarkdown

**THIS WRITTEN TUTORIAL IS STILL WIP**, for now, check the video instead: https://www.youtube.com/watch?v=FdzqToe3dug

# Introduction
TODO: ...write intro here...

This article assumes you have knowledge of Elixir and Phoenix.

# Video
This tutorial is also available as a video on YouTube: https://www.youtube.com/watch?v=FdzqToe3dug. The video also shows a working website with PardallMarkdown, which is the [demo](https://github.com/alfredbaudisch/pardall_markdown_phoenix_demo) repository (see below).

# Finished Product: a Blog and a Documentation website

![](https://raw.githubusercontent.com/alfredbaudisch/pardall_markdown/master/sample_content/static/images/pardall-markdown-instant-render.gif)

If you want to jump straight to the end and see the final result and final code, clone and run the master branch of the [pardall_markdown_phoenix_demo](https://github.com/alfredbaudisch/pardall_markdown_phoenix_demo) repository.

The final project has:
- A Phoenix.LiveView website with both a Blog and a Documentation section.
- Sample content in nested categories.
- Source code of the Phoenix.LiveView routes, views, components and templates, for single posts, archives and categories sidebars.
- Helpers to render the nested content trees and individual posts' table of contents.
 
# Getting Started

1. Clone the starter/skeleton project from the [tutorial_starter branch](https://github.com/alfredbaudisch/pardall_markdown_phoenix_demo/tree/tutorial-starter). The starter project contains:
     - Phoenix.LiveView templates for posts, post archives and content hierarchies (with HTML lists)
     - Phoenix helpers for generating HTML lists from PardallMarkdown content trees (we're going to talk about that below)
     - A Phoenix.LiveView component for showing single posts.
     - The templates use Bootstrap for styling.
2. Into `mix.exs`, add PardallMarkdown as dependency and inside `extra_applications`:
```elixir
defp deps do
  [{:pardall_markdown, "~> 0.1.3"} ...]
end

def application do
  [extra_applications: [:pardall_markdown, ...], ...]
end
```

# Configuration
PardallMarkdown requires top level application configuration, you can see all the possible options [here](https://github.com/alfredbaudisch/pardall_markdown#usage-in-elixir-otp-applications). 

The most important ones to keep in mind are:
- `root_path`: This is your content folder, where all Markdown files live on. This is the folder which [`PardallMarkdown.FileWatcher`](https://github.com/alfredbaudisch/pardall_markdown/blob/master/lib/pardall_markdown/file_watcher.ex) keeps watching for file events, in order to broadcast new and changed content.
	- The path can be either relative or absolute.
- `recheck_pending_file_events_interval`: How often should `FileWatcher` send the content to be rebuilt IF there are pending file events? It does nothing if there are no pending file events.
- `notify_content_reloaded`: Callback to be called everytime the content is rebuilt. This is where you can notify your application about new content, such as calling `Phoenix.PubSub` (or via `Phoenix.Endpoint.broadcast`).

Open the starter project `config.exs` and check those main keys:

```elixir
config :pardall_markdown, PardallMarkdown.Content,
  root_path: "./sample_content",
  recheck_pending_file_events_interval: 1_000,
  notify_content_reloaded: &PardallMarkdownWeb.pardall_markdown_notifier/0
  # [...]
```

The starter project points to a local content folder called `./sample_content`, recheck for pending events every second and calls a content modifier from a root module.

For development purposes, change `recheck_pending_file_events_interval` to a very low value, such as `100` (which is 100ms), so new content is rebuilt immediatelly.

This is the notification callback:
```
  def pardall_markdown_notifier do
    Application.ensure_all_started(:pardall_markdown_phoenix_demo)
    PardallMarkdownWeb.Endpoint.broadcast!("pardall_markdown_web", "content_reloaded", :all)
  end
```

In our project Phoenix.LiveView views will subscribe to the `"pardall_markdown_web"` topic and then re-fetch and re-publish the content. Naturally you can place any callback into `notify_content_reloaded`, because **by being an independent OTP/Elixir application/framework, PardallMarkdown does not require the usage of Phoenix**.


# First post
# Getting data with Repository
# Post template
# Instant reload
# Content tree
# Draft status
# Custom titles
# Showing single posts
# Route catch-all slugs
# Post slug in LiveView
# Image static path
# Table of contents from a Post
# Single post template
# Archives, taxonomy posts
# Archives template
# Multiple templates
# Next and previous links
# Taxonomy `_index`
# Sorting
# Taxonomy index content
# Sidebars and content trees
# Build a Documentation website
# Multiple contents at once
# Sidebar inside a single post
# Sitemap, content and taxonomy trees
# Index page with updated posts
# Sitemap contd.
# Content folder outside the application
# Writing content offline
