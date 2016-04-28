# StatusPage.io Test

Test App is available at: https://frozen-gorge-36844.herokuapp.com/

To test:
```
POST https://frozen-gorge-36844.herokuapp.com/jobs
{urls:['https://www.apple.com']}
```

Response will be a job ID:
```
{id: 1}
```

Check the status at https://frozen-gorge-36844.herokuapp.com/jobs/<id>/status

View the final results at https://frozen-gorge-36844.herokuapp.com/jobs/</id>/results

## Design Decisions

This app is setup around a very light router (app.rb), and a few interesting modules:

- Worker
- Scraper
- ActionHandler

### Worker (lib/worker.rb)

The Worker is a very simple in-memory queue that runs in the background of the web process (so that it can run easily on a Heroku free dyno). At scale it would be much better to run an independent worker process, and this design wouldn't be effective since it needs to be running in the same process as the core app.

The basic idea could be adapted to load queue items via a redis channel or something along those lines, but at that point there are plenty of good existing tools to solve the same problem like Sidekiq or Que.

### Scraper (lib/scraper.rb)

The Scraper class does two closely related tasks: first it offers a class-level shortcut for fetching a url (Scraper.call) and passing it to an instance, and second it creates an instance around an HTML document that can lazy search for links and images.

The link and image searching is moderately robust, though there's room for improvement.

Links are detected simply by searching the document for anchor tags with an href attribute, then filtering out hrefs that begin with '#' and 'mailto'.

Images are detected by searching the img tag and a few other known places for images to be referenced, including any inline styles. A more robust solution could queue up remote stylesheets for fetching and parsing, but I decided that was outside of the reasonable scope for this demo.

I'm not thrilled with the solution for filtering valid URLs. Currently this filter catches *many* cases of invalid URLs but I think it's unlikely that it will catch ALL. More on this in a minute.

### ActionHandler (lib/action_handler.rb)

The ActionHandler is a small object to wrap the business logic for this demo.

It has only one true public interface: #create_job, which is it's primary purpose, but I grouped the loosely related tasks of managing the background queue and processing the pages found in the job -- ie. *processing* the job, together for demo purposes.

As described in the comments in ActionHandler, I usually prefer to make individual service objects that are more single-purpose in nature, ie: CreateJob, CreatePage, ProcessPage etc., and make these simple and composable callables.

However, since these tasks were so closely tied to the operation of the in-memory background worker, it was cleaner to put them together into a single wrapper object.

Either way, keeping the business logic in simple ruby objects like this makes for easy unit testing. In this case, because the instance can wraps the worker queue, any methods that need to go through the background queue can be stubbed and a mock queue used instead, allowing you to test the effects without getting into background threads.

In a real system with the background worker in its own process, it would be a easier to split up the various actions here into discrete callables that could communicate to the background worker without needing a persistent local object to manage the queue, so this design wouldn't make as much since.


### Everything else

Page and Job are very simple, straightforward database-backed models using the Sequel ORM. Nothing special there.

App.rb is a Roda Router, just a little boilerplate to convert HTTP requests into ruby calls and return JSON. Again, nothing special.

### Wrap Up

This was a really interesting project. I felt like this was a good stopping point for a proof of concept, and spent 7h 26m which was about the target time (8h) given.

A few next steps I'd want to do if I were continuing on this project:

1. Design a system for "invalid" Pages - occasionally if a bad URL slips through the scraper it can jam the queue as the page tries to GET a URL that cannot be parsed. In this case it would be better for this failed GET request to bubble back up and cause the page to be marked as "invalid" so the queue is unstuck and it won't retry.

2. Decide on a duplicate-prevention measure. Right now the scraper doesn't attempt  to filter duplicates, because on most reasonable pages there aren't many. Still, including duplicates is silly.

The obvious solution is to make the Job -> Page and Page -> Page relationships many to many, so that any particular Page is only ever created once and can simply be referenced multiple times if needed.

The downside to this approach is there should probably be some tracking of when the page was last fetched, otherwise skipping over previously encountered pages will eventually result in, effectively, a very stale cache.

Another solution is just to filter duplicates at the level of an individual page, but without passing the list of found links around between the children you still get a lot of potential duplicates across the two levels.

I thought about this one a bit but ultimately decided to leave it as is for the demo since I think in real life this is the sort of thing where your larger context and actual use cases would inform what the correct choice was, whereas in a demo like this there is no larger context.

3. Decide on a method for fetching external stylesheets and scraping their images as well. Currently the scraper does fetch images from CSS but only when it is inline. A lot of the web's images are only references in external style sheets though. It would be ideal to setup a new mechanism for queuing the fetch and parse of external stylesheets on each page, but I felt this was a little complicated and outside the scope of this demo.

