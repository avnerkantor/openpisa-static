// Open PISA, static version. Same logic as the Shiny app (pisa.scores.R, pisa.analyze.R)

// texts and data file of the page language (index.html is Hebrew, en.html is English)
var isHebrew = document.documentElement.lang === "he";
var text = isHebrew
  ? {scores: "data/scores.csv", defaults: ["ישראל", "הולנד"], locale: "he",
     xTitle: "שנת מבחן", yTitle: "רמת מיומנות", noData: "לא השתתפו"}
  : {scores: "data/scores_en.csv", defaults: ["United States", "Canada"], locale: "en",
     xTitle: "Test Year", yTitle: "Proficiency Level", noData: "Did not participate"};

var years = [2006, 2009, 2012, 2015, 2018, 2022, 2025];

// score at the bottom of each proficiency level (ExpertiseLevels.csv)
var expertiseLevels = {
  Math:    {1: 358, 2: 420, 3: 482, 4: 545, 5: 607, 6: 669},
  Science: {1: 335, 2: 410, 3: 484, 4: 559, 5: 633, 6: 708},
  Reading: {1: 335, 2: 407, 3: 480, 4: 553, 5: 626, 6: 698}
};
// y axis limits (expertiseLevelsLimits.csv)
var expertiseLevelsLimits = {Math: [306, 684], Science: [271, 723], Reading: [271, 713]};

var groupColours = {
  General: "#b276b2", Male: "#5da5da", Female: "#f17cb0",
  GeneralLow: "#bc99c7", GeneralMedium: "#b276b2", GeneralHigh: "#7b3a96",
  MaleHigh: "#265dab", MaleLow: "#88bde6", MaleMedium: "#5da5da",
  FemaleHigh: "#e5126f", FemaleLow: "#f6aac9", FemaleMedium: "#f17cb0"
};

var pisaScores = [];
var state = {Subject: "Math", Gender: [], Escs: []};

//// Scores ////

function filterScores(country) {
  return pisaScores.filter(function (d) {
    if (d.Country !== country || d.Subject !== state.Subject) return false;
    if (state.Gender.length === 0) {
      if (state.Escs.length === 0) return d.Gender === "0" && d.ESCS === "0";
      return d.Gender === "0" && state.Escs.indexOf(d.ESCS) > -1;
    }
    if (state.Gender.length === 1) {
      if (state.Escs.length === 0) return d.Gender === state.Gender[0] && d.ESCS === "0";
      return d.Gender === state.Gender[0] && state.Escs.indexOf(d.ESCS) > -1;
    }
    return state.Gender.indexOf(d.Gender) > -1 && d.ESCS === "0";
  });
}

// plain SVG line chart (the Plotly library froze some browsers after drawing)
var SVGNS = "http://www.w3.org/2000/svg";
function svgEl(tag, attrs, parent) {
  var e = document.createElementNS(SVGNS, tag);
  Object.keys(attrs).forEach(function (k) { e.setAttribute(k, attrs[k]); });
  if (parent) parent.appendChild(e);
  return e;
}

function scoresPlot(divId, country) {
  var plotData = filterScores(country);
  var groups = {};
  plotData.forEach(function (d) {
    (groups[d.GenderESCS] = groups[d.GenderESCS] || []).push(d);
  });
  var series = Object.keys(groups).map(function (g) {
    return {group: g, rows: groups[g].sort(function (a, b) { return a.Year - b.Year; })};
  });

  var div = document.getElementById(divId);
  div.innerHTML = "";
  div.style.position = "relative";
  div.setAttribute("dir", "ltr");
  var W = div.clientWidth || 400, H = div.clientHeight || 300;
  var narrow = window.innerWidth <= 520;
  var m = narrow ? {t: 10, r: 10, b: 65, l: 40} : {t: 15, r: 20, b: 50, l: 50};
  var levels = expertiseLevels[state.Subject], lim = expertiseLevelsLimits[state.Subject];
  var X = function (year) { return m.l + (year - 2004.5) / (2026.5 - 2004.5) * (W - m.l - m.r); };
  var Y = function (v) { return H - m.b - (v - lim[0]) / (lim[1] - lim[0]) * (H - m.t - m.b); };
  var tick = narrow ? 10 : 12;
  var svg = svgEl("svg", {width: W, height: H, style: "font-family: 'Open Sans', sans-serif; display: block"}, div);

  // y axis: proficiency levels with grid lines
  Object.keys(levels).forEach(function (l) {
    var y = Y(levels[l]);
    svgEl("line", {x1: m.l, x2: W - m.r, y1: y, y2: y, stroke: "#e0e0e0"}, svg);
    svgEl("text", {x: m.l - 6, y: y + 4, "text-anchor": "end", "font-size": tick, fill: "#444"}, svg).textContent = l;
  });
  // x axis: test years
  svgEl("line", {x1: m.l, x2: W - m.r, y1: H - m.b, y2: H - m.b, stroke: "#c7c7c7"}, svg);
  svgEl("line", {x1: m.l, x2: m.l, y1: m.t, y2: H - m.b, stroke: "#c7c7c7"}, svg);
  years.forEach(function (year) {
    var x = X(year), y = H - m.b + 16;
    var t = svgEl("text", {x: x, y: y, "text-anchor": narrow ? "end" : "middle", "font-size": tick, fill: "#444"}, svg);
    if (narrow) t.setAttribute("transform", "rotate(-45 " + x + " " + (y - 4) + ")");
    t.textContent = year;
  });
  svgEl("text", {x: m.l + (W - m.l - m.r) / 2, y: H - 8, "text-anchor": "middle", "font-size": 13, fill: "#777777"}, svg).textContent = text.xTitle;
  svgEl("text", {x: 0, y: 0, "text-anchor": "middle", "font-size": 13, fill: "#777777",
    transform: "translate(12 " + (m.t + (H - m.t - m.b) / 2) + ") rotate(-90)"}, svg).textContent = text.yTitle;

  if (series.length === 0) {
    svgEl("text", {x: X(2015), y: Y(500), "text-anchor": "middle", "font-size": 22, fill: "#c7c7c7"}, svg).textContent = text.noData;
    return;
  }
  series.forEach(function (s) {
    var c = groupColours[s.group];
    if (s.rows.length > 1) {
      svgEl("polyline", {points: s.rows.map(function (d) { return X(d.Year) + "," + Y(d.Average); }).join(" "),
        fill: "none", stroke: c, "stroke-width": 4, "stroke-linejoin": "round", "stroke-linecap": "round"}, svg);
    } else {
      svgEl("circle", {cx: X(s.rows[0].Year), cy: Y(s.rows[0].Average), r: 4.5, fill: c}, svg);
    }
  });

  // hover: the values of every line in the nearest test year
  var guide = svgEl("line", {y1: m.t, y2: H - m.b, stroke: "#c7c7c7", visibility: "hidden"}, svg);
  var tip = document.createElement("div");
  tip.style.cssText = "position:absolute;pointer-events:none;display:none;font-size:15px;line-height:1.3";
  div.appendChild(tip);
  svg.addEventListener("mousemove", function (e) {
    var box = svg.getBoundingClientRect(), px = e.clientX - box.left;
    var year = years.reduce(function (a, b) { return Math.abs(X(b) - px) < Math.abs(X(a) - px) ? b : a; });
    var vals = series.map(function (s) {
      var r = s.rows.filter(function (d) { return d.Year === year; })[0];
      return r ? {c: groupColours[s.group], v: r.Average} : null;
    }).filter(Boolean).sort(function (a, b) { return b.v - a.v; });
    if (vals.length === 0) { guide.setAttribute("visibility", "hidden"); tip.style.display = "none"; return; }
    guide.setAttribute("x1", X(year)); guide.setAttribute("x2", X(year)); guide.setAttribute("visibility", "visible");
    tip.innerHTML = vals.map(function (o) {
      return '<div style="background:' + o.c + ';color:#fff;padding:1px 6px;margin-bottom:2px">' + Math.round(o.v) + "</div>";
    }).join("");
    tip.style.display = "block";
    tip.style.left = (X(year) + (X(year) > W / 2 ? -tip.offsetWidth - 8 : 8)) + "px";
    tip.style.top = Math.max(m.t, Y(vals[0].v) - 12) + "px";
  });
  svg.addEventListener("mouseleave", function () { guide.setAttribute("visibility", "hidden"); tip.style.display = "none"; });
}

function updatePlots() {
  scoresPlot("Country1Plot", document.getElementById("Country1").value);
  scoresPlot("Country2Plot", document.getElementById("Country2").value);
}

//// Buttons logic ////

function activeValues(groupId) {
  return Array.prototype.map.call(
    document.querySelectorAll("#" + groupId + " .active"),
    function (b) { return b.getAttribute("data-value"); });
}

function updateState() {
  state.Subject = activeValues("Subject")[0];
  state.Gender = activeValues("Gender");
  state.Escs = activeValues("Escs");
  // colours of the economic status buttons follow the selected gender
  var mode = state.Gender.length === 0 ? "general" : state.Gender.length === 2 ? "both" : state.Gender[0].toLowerCase();
  document.getElementById("Escs").className = "btn-group " + mode;
  updatePlots();
}

document.querySelectorAll("#Subject button").forEach(function (btn) {
  btn.addEventListener("click", function () {
    document.querySelectorAll("#Subject button").forEach(function (b) { b.classList.remove("active"); });
    btn.classList.add("active");
    updateState();
  });
});

document.querySelectorAll("#Gender button, #Escs button").forEach(function (btn) {
  btn.addEventListener("click", function () {
    btn.classList.toggle("active");
    updateState();
  });
});

document.querySelectorAll(".countrySelect").forEach(function (sel) {
  sel.addEventListener("change", updatePlots);
});

// redraw at the new width when the window size changes
var resizeTimer;
window.addEventListener("resize", function () {
  clearTimeout(resizeTimer);
  resizeTimer = setTimeout(function () { if (pisaScores.length) updatePlots(); }, 150);
});

Papa.parse(text.scores, {
  download: true, header: true, skipEmptyLines: true,
  complete: function (results) {
    pisaScores = results.data.map(function (d) {
      d.Year = +d.Year;
      d.Average = +d.Average;
      return d;
    });
    var countries = [];
    pisaScores.forEach(function (d) { if (countries.indexOf(d.Country) === -1) countries.push(d.Country); });
    countries.sort(function (a, b) { return a.localeCompare(b, text.locale); });
    [["Country1", text.defaults[0]], ["Country2", text.defaults[1]]].forEach(function (s) {
      var sel = document.getElementById(s[0]);
      countries.forEach(function (c) { sel.add(new Option(c, c, false, c === s[1])); });
    });
    updatePlots();
    // the analysis table (2.5MB) loads only after the charts are drawn, so it does not delay them
    setTimeout(loadAnalyze, 0);
  }
});

//// Analyze table ////

var analyzeColumns = ["Country", "Subject", "variable", "r.squared", "p.value", "t.value", "estimate", "std.error", "n"];
var analyzeSelected = ["Country", "Subject", "variable", "r.squared", "p.value", "n"];
var analyzeSearch = {Country: isHebrew ? "Israel" : "United States", Subject: "Math", variable: "Class size (CLSIZE)"};
// columns with a limited set of values get a list of all values, the others a text box
var analyzeLists = ["Country", "Subject", "variable", "p.value"];

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// Country matches as text, so "Israel" also shows its sector groups as in the Shiny app.
// The other lists match the whole value.
function columnSearch(name, value) {
  if (!value) return {search: ""};
  if (analyzeLists.indexOf(name) > -1 && name !== "Country") {
    return {search: "^" + escapeRegex(value) + "$", regex: true, smart: false};
  }
  return {search: value};
}

function sortValues(name, values) {
  if (name === "p.value") {
    var stars = ["***", "**", "*"];
    return values.sort(function (a, b) {
      var ra = stars.indexOf(a), rb = stars.indexOf(b);
      if (ra > -1 || rb > -1) return (ra > -1 ? ra : 9) - (rb > -1 ? rb : 9);
      return parseFloat(a) - parseFloat(b);
    });
  }
  return values.sort(function (a, b) { return a.localeCompare(b, "en"); });
}

function loadAnalyze() {
Papa.parse("data/analyze.csv", {
  download: true, header: false, skipEmptyLines: true,
  complete: function (results) {
    var rows = results.data.slice(1);

    // header: column names and a filter for each column, as in DT filter = 'top'
    var thead = $("<thead>").appendTo("#analyzeTable");
    var titles = $("<tr>").appendTo(thead);
    var filters = $("<tr>").appendTo(thead);
    analyzeColumns.forEach(function (name, i) {
      $("<th>").text(name).appendTo(titles);
      var control;
      if (analyzeLists.indexOf(name) > -1) {
        var seen = {};
        rows.forEach(function (r) { seen[r[i]] = true; });
        control = $("<select>").append($("<option value=''>All</option>"));
        sortValues(name, Object.keys(seen)).forEach(function (v) {
          control.append($("<option>").val(v).text(v));
        });
        control.val(analyzeSearch[name] || "");
      } else {
        control = $("<input type='search' placeholder='All'>");
      }
      $("<th>").append(control.attr("data-column", i)).appendTo(filters);
    });

    var table = $("#analyzeTable").DataTable({
      data: rows,
      deferRender: true,
      orderCellsTop: true,
      pageLength: 5,
      lengthMenu: [5, 10, 25, 50, 100],
      order: [[3, "desc"]],
      columns: analyzeColumns.map(function (name) {
        return {visible: analyzeSelected.indexOf(name) > -1, type: name === "p.value" ? "string" : undefined};
      }),
      searchCols: analyzeColumns.map(function (name) {
        return analyzeSearch[name] ? columnSearch(name, analyzeSearch[name]) : null;
      })
    });

    $("#analyzeTable thead").on("keyup change input", "input, select", function () {
      var index = +$(this).attr("data-column");
      var s = columnSearch(analyzeColumns[index], this.value);
      var column = table.column(index);
      if (column.search() !== s.search) column.search(s.search, !!s.regex, s.smart !== false).draw();
    });

    // which columns to show, as in the show_vars checkboxes
    analyzeColumns.forEach(function (name, i) {
      var box = $("<input type='checkbox'>").prop("checked", analyzeSelected.indexOf(name) > -1)
        .on("change", function () { table.column(i).visible(this.checked); });
      $("<label>").append(box, " " + name).appendTo("#show_vars");
    });
  }
});
}
