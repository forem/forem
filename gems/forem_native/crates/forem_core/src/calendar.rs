//! Calendar grid rendering primitives for `CalendarHelper#calendar_grid_days_html`.
//!
//! Days are exchanged as Ruby `Date#jd` (Julian Day Numbers) so the Ruby caller never
//! has to format dates or build route URLs per cell.

use crate::feed::civil_from_days;

/// `Date.new(1970, 1, 1).jd`.
pub const UNIX_EPOCH_JD: i64 = 2_440_588;
/// `Date.new(1582, 10, 15).jd`: Ruby's `Date` switches from the Julian to the Gregorian
/// calendar here (`Date::ITALY`), so earlier days are left to Ruby.
pub const GREGORIAN_REFORM_JD: i64 = 2_299_161;
/// The grid never spans more than six weeks; anything longer is left to Ruby.
pub const MAX_GRID_DAYS: i64 = 62;

/// Inputs for one month grid, mirroring the instance variables read by
/// `app/views/calendar/_calendar_widget.html.erb`.
#[derive(Debug, Clone, Copy)]
pub struct CalendarGrid<'a> {
    pub grid_start_jd: i64,
    pub grid_end_jd: i64,
    /// `@display_month.month` (1-12).
    pub display_month: u32,
    /// `@event_day_set` as Julian Day Numbers, in any order.
    pub event_day_jds: &'a [i64],
    /// `[@range_start.jd, @range_end.jd]` when `params[:start]` is present.
    pub selected_range: Option<(i64, i64)>,
    pub today_jd: i64,
    /// `calendar_path` with no params.
    pub base_path: &'a [u8],
    /// `params[:type_of].presence`.
    pub type_of: Option<&'a [u8]>,
}

/// Converts a Julian Day Number to a proleptic Gregorian `(year, month, day)`.
#[inline]
pub const fn civil_from_jd(jd: i64) -> (i32, u32, u32) {
    civil_from_days(jd - UNIX_EPOCH_JD)
}

/// Appends `Date#iso8601` (`YYYY-MM-DD`) for years `0..=9999`.
#[inline]
pub fn push_iso8601_date(out: &mut String, year: i32, month: u32, day: u32) {
    let y = year as u32;
    for digit in [y / 1000, (y / 100) % 10, (y / 10) % 10, y % 10] {
        out.push(char::from(b'0' + digit as u8));
    }
    out.push('-');
    push_two_digits(out, month);
    out.push('-');
    push_two_digits(out, day);
}

#[inline]
fn push_two_digits(out: &mut String, value: u32) {
    out.push(char::from(b'0' + (value / 10) as u8));
    out.push(char::from(b'0' + (value % 10) as u8));
}

#[inline]
fn is_url_safe_path(bytes: &[u8]) -> bool {
    bytes.first() == Some(&b'/')
        && bytes
            .iter()
            .all(|&b| b.is_ascii_alphanumeric() || matches!(b, b'/' | b'-' | b'_' | b'.' | b'~'))
}

/// Characters `CGI.escape` leaves untouched that also need no HTML escaping.
#[inline]
fn is_query_safe_value(bytes: &[u8]) -> bool {
    !bytes.is_empty()
        && bytes
            .iter()
            .all(|&b| b.is_ascii_alphanumeric() || matches!(b, b'-' | b'_'))
}

/// Renders the `link_to` anchors for every day in the grid, joined by `"\n"`, exactly as
/// `CalendarHelper#legacy_calendar_grid_days_html` does with `link_to` and `calendar_path`.
///
/// Returns `None` (so Ruby renders the grid itself) when the grid is empty or longer than
/// [`MAX_GRID_DAYS`], falls outside years 1583-9999, the month is not 1-12, or the path or
/// `type_of` would need URL or HTML escaping.
pub fn build_calendar_grid_days_html(grid: &CalendarGrid<'_>) -> Option<String> {
    let CalendarGrid {
        grid_start_jd,
        grid_end_jd,
        display_month,
        event_day_jds,
        selected_range,
        today_jd,
        base_path,
        type_of,
    } = *grid;

    if grid_end_jd < grid_start_jd
        || grid_end_jd - grid_start_jd >= MAX_GRID_DAYS
        || grid_start_jd < GREGORIAN_REFORM_JD
        || !(1..=12).contains(&display_month)
        || civil_from_jd(grid_end_jd).0 > 9999
        || !is_url_safe_path(base_path)
        || type_of.is_some_and(|value| !is_query_safe_value(value))
    {
        return None;
    }
    // Both checks above guarantee these are plain ASCII.
    let base_path = std::str::from_utf8(base_path).ok()?;
    let type_of = match type_of {
        Some(value) => Some(std::str::from_utf8(value).ok()?),
        None => None,
    };

    let mut event_days = event_day_jds.to_vec();
    event_days.sort_unstable();

    let day_count = (grid_end_jd - grid_start_jd + 1) as usize;
    let per_day = 160 + base_path.len() + type_of.map_or(0, |value| value.len() + 13);
    let mut out = String::with_capacity(day_count * per_day);
    let mut iso = String::with_capacity(10);

    for jd in grid_start_jd..=grid_end_jd {
        let (year, month, day) = civil_from_jd(jd);
        iso.clear();
        push_iso8601_date(&mut iso, year, month, day);

        if jd != grid_start_jd {
            out.push('\n');
        }
        out.push_str("<a class=\"calendar__day text-center p-1");
        if month != display_month {
            out.push_str(" color-base-30");
        }
        if event_days.binary_search(&jd).is_ok() {
            out.push_str(" calendar__day--has-event");
        }
        if selected_range.is_some_and(|(start, end)| jd >= start && jd <= end) {
            out.push_str(" calendar__day--selected");
        }
        if jd == today_jd {
            out.push_str(" calendar__day--today");
        }
        out.push_str("\" data-calendar-day=\"");
        out.push_str(&iso);
        out.push_str("\" href=\"");
        out.push_str(base_path);
        // `Hash#to_query` sorts keys: end, start, type_of.
        out.push_str("?end=");
        out.push_str(&iso);
        out.push_str("&amp;start=");
        out.push_str(&iso);
        if let Some(value) = type_of {
            out.push_str("&amp;type_of=");
            out.push_str(value);
        }
        out.push_str("\">");
        if day >= 10 {
            push_two_digits(&mut out, day);
        } else {
            out.push(char::from(b'0' + day as u8));
        }
        out.push_str("</a>");
    }

    Some(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    // Date.new(2026, 10, 1).jd
    const OCT_1_2026: i64 = 2_461_315;

    fn grid<'a>(start: i64, end: i64, events: &'a [i64]) -> CalendarGrid<'a> {
        CalendarGrid {
            grid_start_jd: start,
            grid_end_jd: end,
            display_month: 10,
            event_day_jds: events,
            selected_range: None,
            today_jd: 0,
            base_path: b"/calendar",
            type_of: None,
        }
    }

    #[test]
    fn converts_julian_day_numbers() {
        assert_eq!(civil_from_jd(UNIX_EPOCH_JD), (1970, 1, 1));
        assert_eq!(civil_from_jd(OCT_1_2026), (2026, 10, 1));
        assert_eq!(civil_from_jd(GREGORIAN_REFORM_JD), (1582, 10, 15));
    }

    #[test]
    fn formats_iso8601_dates() {
        let mut out = String::new();
        push_iso8601_date(&mut out, 2026, 3, 9);
        assert_eq!(out, "2026-03-09");
        out.clear();
        push_iso8601_date(&mut out, 1600, 12, 31);
        assert_eq!(out, "1600-12-31");
    }

    #[test]
    fn renders_a_single_day() {
        let html = build_calendar_grid_days_html(&grid(OCT_1_2026, OCT_1_2026, &[])).unwrap();
        assert_eq!(
            html,
            "<a class=\"calendar__day text-center p-1\" data-calendar-day=\"2026-10-01\" \
             href=\"/calendar?end=2026-10-01&amp;start=2026-10-01\">1</a>"
        );
    }

    #[test]
    fn applies_every_class_and_type_of() {
        let events = [OCT_1_2026 + 1];
        let mut g = grid(OCT_1_2026 - 1, OCT_1_2026 + 9, &events);
        g.selected_range = Some((OCT_1_2026 + 1, OCT_1_2026 + 1));
        g.today_jd = OCT_1_2026 + 1;
        g.type_of = Some(b"live_stream");
        let html = build_calendar_grid_days_html(&g).unwrap();
        let lines: Vec<&str> = html.split('\n').collect();
        assert_eq!(lines.len(), 11);
        assert!(lines[0].starts_with(
            "<a class=\"calendar__day text-center p-1 color-base-30\" data-calendar-day=\"2026-09-30\""
        ));
        assert_eq!(
            lines[2],
            "<a class=\"calendar__day text-center p-1 calendar__day--has-event calendar__day--selected \
             calendar__day--today\" data-calendar-day=\"2026-10-02\" \
             href=\"/calendar?end=2026-10-02&amp;start=2026-10-02&amp;type_of=live_stream\">2</a>"
        );
        assert!(lines[10].ends_with(">10</a>"));
    }

    #[test]
    fn crosses_year_boundaries() {
        let dec_31 = OCT_1_2026 + 91;
        let html = build_calendar_grid_days_html(&grid(dec_31, dec_31 + 1, &[])).unwrap();
        assert!(html.contains("data-calendar-day=\"2026-12-31\""));
        assert!(html.contains("data-calendar-day=\"2027-01-01\""));
    }

    #[test]
    fn defers_out_of_domain_inputs() {
        assert!(build_calendar_grid_days_html(&grid(OCT_1_2026, OCT_1_2026 - 1, &[])).is_none());
        assert!(
            build_calendar_grid_days_html(&grid(OCT_1_2026, OCT_1_2026 + MAX_GRID_DAYS, &[]))
                .is_none()
        );
        let pre_reform = GREGORIAN_REFORM_JD - 1;
        assert!(build_calendar_grid_days_html(&grid(pre_reform, pre_reform, &[])).is_none());
        // Date.new(10_000, 1, 1).jd
        let year_10000 = 5_373_485;
        assert!(build_calendar_grid_days_html(&grid(year_10000, year_10000, &[])).is_none());

        let mut g = grid(OCT_1_2026, OCT_1_2026, &[]);
        g.display_month = 13;
        assert!(build_calendar_grid_days_html(&g).is_none());

        for bad in [&b"a b"[..], b"x&y", b"\"", b"", "café".as_bytes(), b"a.b"] {
            let mut g = grid(OCT_1_2026, OCT_1_2026, &[]);
            g.type_of = Some(bad);
            assert!(build_calendar_grid_days_html(&g).is_none(), "{bad:?}");
        }
        for bad in [&b""[..], b"calendar", b"/cal?x=1", b"/cal#x", b"/cal\"x"] {
            let mut g = grid(OCT_1_2026, OCT_1_2026, &[]);
            g.base_path = bad;
            assert!(build_calendar_grid_days_html(&g).is_none(), "{bad:?}");
        }
    }
}
