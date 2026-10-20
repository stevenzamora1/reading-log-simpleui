# Reading Log for Simple UI

**Reading dashboard cards for KOReader's [Simple UI](https://github.com/doctorhetfield-cmd/simpleui.koplugin) home screen.**

Activity rings, monthly and yearly charts, reading trends, a monthly
challenge, finish forecasts, library stats, a random pick from your unread
books, your own highlights, a Control centre and more: 31 cards, a Mini
dashboard, and a tabbed Dashboard that puts them together. No Bookshelf
needed.

This is the Simple UI version of [Reading Log for Bookshelf](https://github.com/stevenzamora1/reading-log).

<p align="center">
  <img src="screenshots/dashboard-today.png" width="32%" alt="Dashboard, Today page">
  <img src="screenshots/dashboard-trends.png" width="32%" alt="Dashboard, Trends page">
  <img src="screenshots/dashboard-library.png" width="32%" alt="Dashboard, Library page">
</p>

## Screenshots

| Today | Yearly | Monthly |
| :---: | :---: | :---: |
| <img src="screenshots/dashboard-today.png" width="260" alt="Today page"> | <img src="screenshots/dashboard-yearly.png" width="260" alt="Yearly page"> | <img src="screenshots/dashboard-monthly.png" width="260" alt="Monthly page"> |
| The time, Continue reading, today's rings, the week, the book club and the Control centre | Time read, longest reads, books and pages by month, and every cover you finished this year | Month rings, the month's totals, pages per day, when you read, and longest reads. Step back up to twelve months |

| Trends | Library | On the home screen |
| :---: | :---: | :---: |
| <img src="screenshots/dashboard-trends.png" width="260" alt="Trends page"> | <img src="screenshots/dashboard-library.png" width="260" alt="Library page"> | <img src="screenshots/home-screen-cards.png" width="260" alt="Cards on Simple UI's home screen"> |
| The monthly challenge, finish forecast, and your last 90 days against your year | Library stats, this week's random pick, most-read authors and a quote from your highlights | Cards on their own, alongside Simple UI's own modules |

## What you need

- [KOReader](https://koreader.rocks) with [Simple UI](https://github.com/doctorhetfield-cmd/simpleui.koplugin) **2.7.5 or newer**.
- KOReader's **Reading statistics** plugin switched on (it is by default). All the reading figures come from it.
- Bookshelf is **not** needed. A colour screen is optional; on a black-and-white screen the colours show as greys.

## Install

1. Download `readinglog-simpleui-1.1.0.zip` from [Releases](../../releases) and unzip it.
2. Copy the `readinglog.koplugin` folder into KOReader's `plugins` folder:
   - Kobo: `.adds/koreader/plugins/` (`.adds` is hidden: in macOS Finder press <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>.</kbd>; in Windows Explorer choose View > Show > Hidden items)
   - Kindle: `/mnt/us/koreader/plugins/`
   - Android: `<koreader folder>/plugins/`
3. Eject the e-reader and restart KOReader.

**Updating:** replace the folder and restart. Your settings are kept (they live in `settings/readinglog.lua`, outside the plugin folder).

## Add cards

Simple UI Settings > **Home Screen** > **Layout Editor**, open a page, tap **Add Module**, and pick any `Reading Log · …` module. Set a card's Column Width to 50% (long-press > Column Width) to put two side by side.

Long-press any card for its settings.

## The cards

| Today | Monthly | Yearly |
| --- | --- | --- |
| Banner (time and date) | Month rings | Time read by month |
| Continue reading | Month totals | Longest reads of the year |
| Activity rings | Pages per day | Books and pages by month |
| Week rings | When you read | Year in covers |
| This week | Longest reads of the month | Reading heatmap |
| Year goal | Monthly challenge | Top genres |
| Book club | | Recently finished |
| Today's timeline | | |
| Control centre | | |

| Trends | Library | Shelves |
| --- | --- | --- |
| Reading trends | Library stats | TBR shelf |
| This week vs last | Most-read authors | Finish by |
| Finish forecast | Random pick | |
| | Quote of the day | |

### New in 1.1

- **Reading trends**: your last 90 days against your year (time, pages, reading days, session length, speed, books finished).
- **Monthly challenge**: one goal for the month, picked from your last three months or set by you.
- **Finish forecast**: when you'll finish the books you're reading at your recent pace, and where your year is heading.
- **This week vs last**: your average a day this week against last week (or month, or year).
- **Today's timeline**: each sitting today on a line through the day.
- **Control centre**: up to 8 buttons for any action, with brightness and warmth.
- **Library stats**, **Most-read authors**, **Random pick** (only the next book of a series) and **Quote of the day** (from your own highlights).
- **Mini dashboard**: one row of up to three small cards for the top of the home screen.
- **Dashboard**: Trends and Library pages, up to 7 tabs, move tabs, remove pages you added, reset the whole Dashboard.
- **Text size** for every card and for the whole Dashboard.
- **Finish dates**: a book reopened for a moment no longer moves to today's date.

## The Dashboard

The Dashboard puts the cards together as tabbed pages (Today, Yearly, Monthly, Trends and Library) and is meant to fill a screen on its own.

1. Simple UI Settings > **Extra Custom Screens**: create one (call it "Reading Log", say). Simple UI gives it a Quick Action, so you can put it on the navigation bar.
2. Open its layout and add **Reading Log · Dashboard** on its own.
3. Long-press the Dashboard and set **Top Margin** to 0 and **Height** to Fill the page.

Tap the tabs to switch pages. On the Monthly page the arrows step back one month at a time, and every card on the page follows.

Long-press > **Pages and cards…** to change it: any card on any page, one or two cards per row, row heights, tab names, pages shown or hidden, **+ Add a page** (up to 7 tabs), **Move tab left / right**, and **Remove this page**. **Put the whole Dashboard back as it came…** resets the layout and keeps each card's settings and the colours.

## The Mini dashboard

**Reading Log · Mini dashboard** is one row of up to three small cards. It starts with the book you're reading and today's rings, then the Control centre. Long-press > Content to swap in Continue reading, Activity rings, This week vs last, Week rings, Monthly challenge, Finish forecast, Year goal, Today's timeline, Random pick, Quote of the day or Library stats.

## Settings

Long-press a card. Next to Simple UI's own Frame, Background, Top Margin and Column Width:

- **Content**: the card's own options (goals, collections, how many books, the banner's lines, the book club's picks, the challenge target, …).
- **Appearance**: **Card height**, **Text size** (70–150%), **Card colour**, and **Look and colours** for all cards at once: theme (White, Dark or Paper), two accent colours from twelve, how cards look on their own, and the day the week starts on.
- **When tapped**: the card's own action, the reading calendar, reading progress, or any Simple UI Quick Action.

**Control centre buttons:** long-press > Content > tap a button. **Action…** picks a KOReader action (Wi-Fi, night mode, light, rotate, calendar, sleep, search, last book, history, favorites, …) or any Simple UI Quick Action; **Icon…** picks one of 37 icons; **Name** renames it.

## Shared with Simple UI

- **Goals**: the year's book goal and the daily minutes goal are Simple UI's Reading goals. Change them in either place.
- **Books finished** are counted the way Simple UI's Reading goals count them, so the numbers agree.
- **Books**: titles and authors include your custom metadata, covers come from Simple UI's cover cache, and "Details" opens Simple UI's book menu.
- **Your library**: Library stats, Most-read authors and Random pick count the books under KOReader's home folder. Titles, authors, series and genres come from the cover browser, so a book it hasn't seen yet shows its file name.
- **Highlights**: Quote of the day picks one highlight a day from the books in your history. Another gives the next.

## Coming from Reading Log for Bookshelf

On the first start, your Bookshelf-version settings (theme, accents, collections, book club picks, Dashboard pages, card colours) are copied across. To copy them again: KOReader menu > Tools > **Reading Log** > Copy settings from the Bookshelf version. Both versions can be installed at once.

## Troubleshooting

- KOReader menu > Tools > Reading Log > **About** shows whether Simple UI was found.
- Look and colours > **Diagnostics** shows the versions, theme and screen.
- Problems are logged to `crash.log` with `[readinglog]`.

## Credits

- [u/fishnoogz](https://www.reddit.com/user/fishnoogz/) on Reddit, whose post inspired the ring designs and the dashboard idea.
- [Simple UI](https://github.com/doctorhetfield-cmd/simpleui.koplugin) by Doctor Hetfield, which these modules plug into.
- [Bookshelf](https://github.com/AndyHazz/bookshelf.koplugin) by AndyHazz, where the cards started.
- [BrownTigerz (TK)](https://github.com/BrownTigerz/simpleui_readinglog.koplugin), whose finish-date correction this version uses.
- [KOReader](https://github.com/koreader/koreader) and its Reading statistics plugin.

Made by Steven ([@stevenzamora1](https://github.com/stevenzamora1)).

## License

[AGPL-3.0](LICENSE), the same licence as KOReader.
