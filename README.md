# LiveMarkdown

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
## Split into 3 projects
- Phoenix helpers (i.e. content tree links or maybe put this into the project LiveMarkdown Web example?)
- LiveMarkdown
- LiveMarkdown Web example

## Post metadata/attributes
- Custom title and date
- :published
- Additional custom fields (saved into `%Post{}.metadata`)

## Multiple sorting types
- title, date, slug, position
- Per folder sorting (i.e. a blog can sort by date, while a documentation by position)

## Taxonomy and Content Trees

## File watcher back pressure
- Overkill? Yes.
- Content reloader is already busy processing #{processing} event(s) (for a total of #{pending} pending event(s)). Will re-schedule. If this happens frequently, consider increasing the interval :recheck_pending_file_events_interval.

## Post sets
## Does it require a database?
No.

## Why does it use Ecto?
- Eventually to add a database layer, if needed?
- Being used for Post validation

# TODO: Licenses
- Dashbit Nimblepublisher
- This project's license