function timeAgo(oldTimeInSeconds, maxDisplayedAge = 60*60*24-1) {
  const timeNow = new Date() / 1000;
  const diff = Math.round(timeNow - oldTimeInSeconds);

  if(diff > maxDisplayedAge)
    return '';

  return "<span class='time-ago-indicator'>(" + secondsToHumanUnitAgo(diff) + ")</span>";
}

function secondsToHumanUnitAgo(seconds) {
	const times = [
		['second', 1],
		['min', 60],
		['hour', 60*60],
		['day', 60*60*24],
		['week', 60*60*24*7],
		['month', 60*60*24*30],
		['year', 60*60*24*365],
	];

	if(seconds < times[0][1])
		return "Just now";

	let scale = 0;
	while(scale+1 < times.length && seconds >= times[scale+1][1])
		scale++;

	const wholeUnits = Math.floor(seconds / times[scale][1]);
	const unitName = times[scale][0] + (wholeUnits === 1 ? '' : 's');

	return wholeUnits + " " + unitName + " ago";
}
