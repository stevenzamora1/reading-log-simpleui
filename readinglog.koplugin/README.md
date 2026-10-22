# Reading Log for Simple UI

**The Reading Log cards as modules for Simple UI's home screen, made for colour e-ink.**

Activity rings, monthly and yearly charts, reading trends, a monthly
challenge, finish forecasts, library stats, a random pick from your unread
books, your own highlights, a Control centre and more: the same 31 cards, the
Mini dashboard and the tabbed Dashboard (Today, Yearly, Monthly, Trends,
Library) as [Reading Log for Bookshelf](https://github.com/stevenzamora1/reading-log),
running as [Simple UI](https://github.com/doctorhetfield-cmd/simpleui.koplugin)
modules instead of Bookshelf micro-modules.

The ring designs and the idea of a reading dashboard come from
[u/fishnoogz](https://www.reddit.com/user/fishnoogz/)'s Reddit post.

## What you need

- [KOReader](https://koreader.rocks) with the
  [Simple UI](https://github.com/doctorhetfield-cmd/simpleui.koplugin) plugin,
  2.7.5 or newer.
- KOReader's **Reading statistics** plugin switched on (it is by default).
  All the reading figures come from it.
- Bookshelf is **not** needed. A colour screen is optional; on a
  black-and-white screen the colours show as greys.

## Install

1. Copy the `readinglog.koplugin` folder into KOReader's `plugins` folder:
   - Kobo: `.adds/koreader/plugins/` (`.adds` is hidden: in macOS Finder
     press <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>.</kbd>, in Windows Explorer
     choose View > Show > Hidden items)
   - Kindle: `/mnt/us/koreader/plugins/`
   - Android: `<koreader folder>/plugins/`
2. Eject the e-reader and restart KOReader.

**Updating:** Tools > Reading Log > Check for updates (below), or replace the
folder and restart. Your settings are kept (they
live in `settings/readinglog.lua`, outside the plugin folder; the highlight
counts for Quote of the day sit beside it in `readinglog_highlights.lua`).

## Updates

KOReader menu > Tools > **Reading Log** > **Check for updates** looks for a
newer release on GitHub, shows what's new, and installs it when you say so.
Restart KOReader afterwards; your settings are kept. **Check for updates
automatically** looks once a day when you're already online, and never
installs without asking.

## Add cards

Simple UI Settings > **Home Screen** > **Layout Editor**, open a page, tap
**Add Module**, and pick any `Reading Log · …` module. They sit alongside
Simple UI's own modules, two side by side if you set their Column Width to
50% (long-press > Column Width).

Long-press any card for its settings.

New in 1.2: **Spanish, French, Brazilian Portuguese and Italian** (numbers,
dates and plurals follow your language too), the Dashboard follows Simple
UI's wallpaper Background Opacity, and **Check for updates** in the Reading
Log menu.

New in 1.1:

| Card | What it shows |
| --- | --- |
| Reading trends | Your last 90 days against your year: time, pages, reading days, session length, speed, books finished |
| Monthly challenge | One goal for the month (pages, minutes or reading days), picked from your last three months or set by you |
| Finish forecast | When you'll finish the books you're reading at your recent pace, and where your year is heading |
| This week vs last | Your average a day this week against last week (or month, or year) |
| Today's timeline | Each sitting today on a line through the day, and the book it was |
| Control centre | Up to 8 buttons for any action, with brightness and warmth |
| Library stats | How many books you have, have read, are reading and haven't started |
| Most-read authors | By books finished or by hours read |
| Random pick | A book you haven't started, from your library, a collection, genres or authors (only the next book of a series) |
| Quote of the day | One of your own highlights each day, with its book |

## The Mini dashboard

**Reading Log · Mini dashboard** is one row of up to three small cards, for
the top of the home screen. It starts with the book you're reading and
today's rings, then the Control centre. Long-press > Content to pick other
small cards: Continue reading, Activity rings, This week vs last, Week rings,
Monthly challenge, Finish forecast, Year goal, Today's timeline, Random pick,
Quote of the day or Library stats. As many as fit the width are shown.

## Set up the Dashboard

The Dashboard puts the cards together as tabbed pages (Today, Yearly,
Monthly, Trends and Library), and is meant to fill a screen on its own.

1. Simple UI Settings > **Extra Custom Screens**: create one (call it
   "Reading Log", say). Simple UI gives it a Quick Action, so you can put it
   on the navigation bar.
2. Open its layout and add **Reading Log · Dashboard**, on its own.
3. Long-press the Dashboard and set **Top Margin** to 0. It then fills the
   page (Appearance > Height: Fill the page).

Tap the tabs at the bottom to switch pages. On the Monthly page the big arrows
step back one month at a time (up to twelve months), and every card on the
page follows.

Change the pages with long-press > Content > **Pages and cards…**: any card on
any page, a row of one card or two, each row's height, tab names, pages shown
or hidden, **+ Add a page** (up to 7 tabs), **Move tab left / right**, and
**Remove this page** for pages you added. **Put the whole Dashboard back as it
came…** resets every page, tab and row, and keeps each card's settings and
the colours.

The Dashboard also works on a Home Screen page of its own.

## Settings

Long-press a card. Next to Simple UI's own Frame, Background, Top Margin and
Column Width:

- **Content**: the card's own options (goals, collections, how many books,
  the banner's two lines, the book club's picks for the month, …).
- **Appearance**: **Card height** (against the shape the card was designed
  at), **Text size** (70–150%: small text grows fully, big figures and titles
  by half), **Card colour** (plain or tinted, which accent leads), and **Look and
  colours** for all cards at once: theme (White, Dark or Paper), two accent
  colours from twelve, how cards look on their own (matching Simple UI, or
  framed in the theme), the day the week starts on, and Diagnostics.
- **When tapped**: the card's own action, the reading calendar, reading
  progress, or any of Simple UI's Quick Actions (including your own).
  Buttons on a card (Continue, Details, the tabs) keep their own job.

**Control centre buttons:** long-press > Content > tap a button. **Action…**
picks a KOReader action (Wi-Fi, night mode, light, rotate, calendar, sleep,
search, last book, history, favorites, …) or any Simple UI Quick Action;
**Icon…** picks one of 37 icons; **Name** renames it. The Mini dashboard's
Control centre uses the same buttons.

## Languages

The cards, the Dashboard and their settings follow KOReader's language
(Settings > Language): **English**, **Italian**, **Spanish**, **French** and
**Brazilian Portuguese** (also used for Portuguese from Portugal). Numbers,
dates, day and month initials and plurals follow the language too (14.894
and "1 libro / 2 libros" in Spanish, for example). Book titles, authors,
genres and names you type in are shown as they are. Restart KOReader after
changing the language.

Each language is one file in `readinglog/locales/`. To add one, see
[TRANSLATING.md](TRANSLATING.md).

## Wallpaper

With a Simple UI wallpaper on, the Dashboard follows its **Background
Opacity** (long-press > Background): below Solid, the Dashboard's page is
left clear so the wallpaper shows around and between the cards. The cards
and the tab bar stay solid so they stay readable, and the date, time and
page titles at the top get a framed plate behind them. Cards on their own that
match Simple UI already draw no background of their own.

## Shared with Simple UI

- **Goals.** The year's book goal and the daily minutes goal are Simple UI's
  Reading goals: change them in either place.
- **Books finished.** Counted the way Simple UI's Reading goals count them
  (its finished-books list on newer Simple UI; finished sidecars and "read
  outside KOReader" on 2.7.x), so the Year goal card agrees with it.
- **Finish dates.** Reopening a finished book for a moment can make KOReader
  mark it finished again with today's date. Reading Log uses the last day of
  real reading instead (at least 1 minute or 2 pages), so Longest reads, the
  monthly lists and Year in covers stay right. (In the rare case that moves a
  book into last year, the Year goal card counts it there.)
- **Books.** Titles and authors include your custom metadata; time left is
  the same estimate Simple UI's Currently Reading shows; covers come from
  Simple UI's cover cache, and a cover still being extracted is drawn in when
  it is ready.
- **Book details.** "Details" and a tap on a cover open Simple UI's book menu
  (status, collections, book information, …).
- **Your library.** Library stats, Most-read authors and Random pick count the
  books under KOReader's home folder (the same books Simple UI's Library
  module shows). Titles, authors, series and genres come from the cover
  browser's database, so a book shows its real title once the cover browser
  has seen it; until then, its file name.
- **Highlights.** Quote of the day picks from the highlights in the books in
  your history, one a day (Another gives the next).

## Coming from Reading Log for Bookshelf

On the first start, your Bookshelf-version settings (theme, accents, banner
lines, collections, book club picks, Dashboard pages, card colours) are copied
across. Both versions can be installed at once.

## How it's put together

| File | Why it is there |
| --- | --- |
| `main.lua` | Registers every card with Simple UI's module registry (Simple UI's own hook for other plugins' modules) and adds the Tools menu. |
| `updater.lua` | Check for updates: asks GitHub for the latest release, downloads its zip and unpacks it over the plugin folder with KOReader's own archive reader. |
| `readinglog/init.lua` | The drawing kit: themes, colours, rings, text, the Canvas each card is drawn on. Unchanged from the Bookshelf version apart from where it asks the host for things. |
| `readinglog/host.lua` | Everything that used to come from Bookshelf, now from Simple UI and KOReader: the settings file, fonts, book facts, the library and its metadata, highlights, goals, finished books, covers, opening a book, quick actions, redrawing one card in place, and the once-a-minute clock. |
| `readinglog/data.lua` | Reading figures from the statistics database, read off the paint path and cached. |
| `readinglog/panels.lua` | One builder per card, and the Mini dashboard's small cards. The same file as the Bookshelf version. |
| `readinglog/modules.lua` | Turns each card into a Simple UI module (build, height, tap regions), and the Dashboard. |
| `readinglog/settings.lua`, `menus.lua` | Each card's options, written once and shown as Simple UI settings menus (and dialogs for the page editor and book club picks). |
| `readinglog/i18n.lua`, `i18n/es.lua`, `i18n/fr.lua`, `i18n/pt_BR.lua` | The translations, applied where text is shown, so the cards themselves stay as written. |
| `readinglog/colourtext.lua` | Keeps coloured text coloured on a colour screen (KOReader's text widget turns it grey). |

## Troubleshooting

- KOReader menu > Tools > Reading Log > **About** says whether Simple UI was
  found.
- Look and colours > **Diagnostics** shows the versions, theme and screen.
- Problems are logged to `crash.log` with `[readinglog]` or `[almanac]`.

## Credits

- [u/fishnoogz](https://www.reddit.com/user/fishnoogz/) on Reddit, whose post
  inspired the ring designs and the dashboard idea.
- [Simple UI](https://github.com/doctorhetfield-cmd/simpleui.koplugin) by
  Doctor Hetfield, which these modules plug into.
- [Bookshelf](https://github.com/AndyHazz/bookshelf.koplugin) by AndyHazz,
  where the cards started; `colourtext.lua` is adapted from it.
- [Reading Log for SimpleUI](https://github.com/BrownTigerz/simpleui_readinglog.koplugin)
  by BrownTigerz (TK), whose finish-date correction this version uses.
- [DevGizmo86](https://github.com/DevGizmo86), for the translation system
  and the Italian translation.
- [KOReader](https://github.com/koreader/koreader) and its Reading statistics
  plugin, where all the numbers come from.

Made by Steven ([@stevenzamora1](https://github.com/stevenzamora1)).

## License

[AGPL-3.0](LICENSE), the same licence as KOReader and the Bookshelf version.
