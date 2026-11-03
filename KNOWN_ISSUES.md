# Known issues

## Three different "healthy day" thresholds

The app decides whether a day was healthy in three different ways. They disagree on any day with a risk index between 0.40 and 0.50.

| Where | Rule | Location |
|---|---|---|
| Server count (`healthy_days_30`) | Risk index at or below 0.40 | `computeHealthyDays30` in `functions/ddc/vitality_all_in_one.js` |
| Home chart bar colors | Healthy under 0.45, borderline 0.45 to 0.55, not healthy over 0.55 | `_colorFor` in `lib/features/home/components/healthy_days_mini_bar.dart` |
| Home chart tooltip and local count | Healthy under 0.50 | `lib/features/home/components/healthy_days_mini_bar.dart` |

The server's 0.40 line is also hard to reach. Recovery compares each day with the user's own recent average, so it sits near 0.50 on an ordinary day, which puts the risk index at about 0.40 even with good sleep and activity.

**Status:** not fixed, because choosing one rule changes the scoring behavior. The demo's sample data keeps the bar colors, count and tooltip in agreement, but ordinary demo days do go above the server's 0.40.
