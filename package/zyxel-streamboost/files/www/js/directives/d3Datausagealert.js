(function () {
  'use strict';
  angular.module('ZyXEL.directives')
    .directive('d3Datausagealert', ['d3', function(d3) {
      return {
        restrict: 'EA',
        scope: {
          data: "=",
          label: "@",
          onClick: "&"
        },
        link: function(scope, iElement, iAttrs) {

          var svg = d3.select(iElement[0])
              .append("svg")
              .attr("width", "100%");

          var enabled = true;

          // on window resize, re-render d3 canvas
          window.onresize = function() {
            return scope.$apply();
          };
          scope.$watch(function(){
              return angular.element(window)[0].innerWidth;
            }, function(){
              return scope.render(scope.data);
            }
          );

          // watch for data changes and re-render
          scope.$watch('data', function(newVals, oldVals) {
            if (newVals == oldVals) {
              return;
            }
            return scope.render(newVals);
          }, true);

          var DURATION = 1500;
          var DELAY    = 500;
          var DETAIL_HEIGHT = 25;
          var SVGHeight = 500;
          var DATAImageSize = { width: 54, height:48 };

          var detailContainer = null;
          var showDataUsage = true;

          // define render function
          scope.render = function(data){

            if (scope.enabled == false) {
              return;
            }

            // remove all previous items before render
            svg.selectAll("*").remove();

            if (data == null || data.length == 0) {
              return;
            }

            // console.log("data: ");
            // console.log(data);

            var marginUpload = {top: 10 + DETAIL_HEIGHT, right: 10, bottom: 315, left: 80},
                height = SVGHeight - marginUpload.top - marginUpload.bottom,

                marginBrush = {top: 30 + height + marginUpload.top  , right: 10, bottom: 250, left: 80},
                height2 = SVGHeight - marginBrush.top - marginBrush.bottom,

                marginDownload = {top: 30 + DETAIL_HEIGHT * 2 + marginBrush.bottom , right: 10, bottom: 20, left: 80},
                height3 = SVGHeight - marginDownload.top - marginDownload.bottom;

            var width = d3.select(iElement[0])[0][0].offsetWidth - marginUpload.left - marginUpload.right;

            if (width < 20) {
                width = $('body').width() - marginUpload.left - marginUpload.right;
                if (width < 20) {
                    return;
                }

                svg.attr("width", width)
                   .attr("height", height);
            }
            else {
                svg.attr("width", "100%")
                    .attr("height", height);
            }

            var svgBoundingBox = bboxOfElement(d3.select(".boundingRect").node());

            if (svgBoundingBox.width == 0) {
                svgBoundingBox = bboxOfElement(svg.node());
                if (svgBoundingBox.width == 0) {
                    svgBoundingBox.width = width;
                }
            }

            svg.append("rect")
              .attr("class", "boundingRect")
              .attr("width", "100%")
              .attr("height", "100%")
              // .attr("fill", "gray");
              .style("opacity", 0.0);

            var rightDataAlertPanelWidth = 140;

            if (width > rightDataAlertPanelWidth) {
                width -= rightDataAlertPanelWidth;
            }
            else {
                rightDataAlertPanelWidth = 0;
            }

            var x = d3.time.scale().range([0, width]),
                x2 = d3.time.scale().range([0, width]),
                xDataPlan = d3.time.scale().range([rightDataAlertPanelWidth + 80, width - 80]),
                y = d3.scale.linear().range([height, 5]),
                y2 = d3.scale.linear().range([height2, 0]),
                y3 = d3.scale.linear().range([height3, 5]);


            var dateFormatValue = d3.time.format("%m/%d %H:00");
            var dateDataPlanFormatValue = d3.time.format("%m/%d");
            var yFormatValue = d3.format(".1f");
            var commaFormat = d3.format(",");

            var xAxis = d3.svg.axis().scale(x).orient("bottom")
                            .tickFormat(function(d){ return dateFormatValue(d)}),
                xAxisDataPlan = d3.svg.axis().scale(xDataPlan).orient("bottom")
                                .ticks(d3.time.days, 1)
                                .tickFormat(function(d){ return dateDataPlanFormatValue(d)}),
                xAxis2 = d3.svg.axis().scale(x2).orient("bottom")
                            .tickFormat(function(d){ return dateFormatValue(d)}),
                yAxis = d3.svg.axis().scale(y).orient("left")
                            .tickFormat(function(d){ return yFormatValue(d)});

            svg.attr("height", SVGHeight);

            var clipPathRect = svg.append("defs").append("clipPath")
                                    .attr("id", "clip")
                                  .append("rect")
                                    .attr("width", width)
                                    .attr("height", height);

            var clipPathRectD = svg.append("defs").append("clipPath")
                                    .attr("id", "clipD")
                                  .append("rect")
                                    .attr("width", width)
                                    .attr("height", height3)

                var focusUpload = svg.append("g")
                    .attr("class", "focus")
                    .attr("transform", "translate(" + marginUpload.left + "," + marginUpload.top + ")");


                //////////////////////////////////////////////////
                /// Upload Max
                var yUploadMax = d3.max(data.map(function(d) { return d.tx; }));

                if (yUploadMax == 0) {
                  yUploadMax = 1;
                }

                var brushMaxUsingUpload = true;

                //////////////////////////////////////////////////
                /// Download Max
                var yDownloadMax = d3.max(data.map(function(d) { return d.rx; }));

                if (yDownloadMax == 0) {
                  yDownloadMax = 1;
                }

                //////////////////////////////////////////////////
                /// Adjust data
                var maxValueUnit = valueAndUnitAdjusted(yDownloadMax + yUploadMax, scope.unitUpload);

                if (scope.unitUpload != maxValueUnit.unit) {
                  scope.unitUpload = maxValueUnit.unit;
                  scope.unitDownload = maxValueUnit.unit;
                  var divisor = divisorFromUnit(scope.unitUpload);
                  if (divisor > 1) {
                    yDownloadMax /= divisor;
                    yUploadMax /= divisor;
                    for (var index in data) {
                      data[index].tx /= divisor;
                      data[index].rx /= divisor;
                    }
                  }
                }

                if (scope.dataUsageInfo == null) {
                    scope.dataUsageInfo = {
                        currentDataUsage: 0,
                    	remainingDataUsage: 0
                    }
                }

                //////////////////////////////////////////////////
                /// Calculate statistics
                var statistics = statisticsFromData();

                console.log(statistics);

                //////////////////////////////////////////////////
                /// Validate initial brush indexes.
                var initialBrushIndex = {begin:0, end:0};
                if (scope.initialBrushIndex != null) {
                    initialBrushIndex = scope.initialBrushIndex;
                    if (initialBrushIndex.begin < 0 || initialBrushIndex.begin >= data.length) {
                        initialBrushIndex.begin = 0;
                    }
                    if (initialBrushIndex.end < 0 || initialBrushIndex.end >= data.length) {
                        initialBrushIndex.end = data.length;
                    }
                }

                // console.log("initialBrushIndex:");
                // console.log(initialBrushIndex);

                x.domain([data[initialBrushIndex.begin].date, data[initialBrushIndex.end].date]);
                xDataPlan.domain([statistics.dataUsageInfo.dateRange.start, statistics.dataUsageInfo.dateRange.end]);
                y.domain([0, yUploadMax + yDownloadMax]);
                x2.domain(d3.extent(data.map(function(d) { return d.date; })));
                y2.domain([0, yUploadMax + yDownloadMax]);
                y3.domain([0, yDownloadMax]);

                var brush = d3.svg.brush()
                    .x(x2)
                    .extent([data[initialBrushIndex.begin].date, data[initialBrushIndex.end].date]) //trying to intialize brush
                    .on("brush", brushed);

                //////////////////////////////////////////////////
                /// startData for animation purpose
                var startData = data.map( function( datum ) {
                                  return {
                                    date  : datum.date,
                                    tx : 0,
                                    rx: 0
                                  };
                                } );

                var stackData = data.map(function(datum) {
                    return [{
                        date: datum.date,
                        y: datum.rx,
                        y0: 0
                    },
                    {
                        date: datum.date,
                        y: datum.tx,
                        y0: datum.rx
                    },
                    {
                        date: datum.date,
                        y: yUploadMax + yDownloadMax - datum.rx - datum.tx,
                        y0: datum.rx + datum.tx
                    }];
                });

                var color = ["#30bee7", "#7bea91", "#f9f9f9"];

                var barWidth = getStackBarWidthByBrushIndexes(initialBrushIndex);

                focusUpload.append("g")
                    .style('clip-path', 'url(#clip)')
                    .attr("class", "bars")
                        .selectAll(".bar.stack")
                            .data(stackData)
                            .enter().append("g")
                            .attr("class", "bar stack")
                        .selectAll("rect")
                        .data(function(d) { return d; })
                            .enter().append("rect")
                            .attr("class", "bar unitBar")
                            .attr("width", barWidth)
                            .attr("transform", function(d) { return "translate(" + (x(d.date) - barWidth / 2) + ",0)"; })
                            .attr("y", function(d) { return y(d.y0 + d.y); })
                            .attr("height", 0)
                            .style("fill", function(d, i) { return color[i]; })
                            .transition()
                                .delay(function(d, i) { return i * 10; })
                                .attr("height", function(d) { return y(d.y0) - y(d.y0 + d.y); })

                var dateTicksUpload = focusUpload.append("g")
                  .style('clip-path', 'url(#clip)')
                  .attr("class", "x axis")
                  .attr("transform", "translate(0," + height + ")")
                  .call(xAxis)
                  .selectAll('.tick');

                removeOverlappingTicks(dateTicksUpload);

                //////////////////////////////////////////////////
                /// Data average used indicator

                var xLineDataPlan = svg.append("g")
                                    .attr("class", "x axisDataPlan")
                                    .attr("transform", "translate(0," + (height + height2 + 245 ) + ")");

                var dateTicksDataPlan = xLineDataPlan
                    .call(xAxisDataPlan)
                    .selectAll('.tick');

                removeOverlappingTicks(dateTicksDataPlan);

                var circleOfCurrentDate = xLineDataPlan.append("circle")
                    .attr("transform", "translate(" + xDataPlan(statistics.dataUsageInfo.today) + ", 0)")
                    .attr("r", 4);

                // 70 50
                var markPath = "M23.1,67.1c-7.2-11-14.9-21.6-20.2-33.7C-2.4,21,3.8,6.7,16.2,2.3c12.3-4.4,25.8,2.9,29.2,16 c1.5,5.6,0.8,11.1-1.7,16.5C38.3,46.3,31,56.5,24.1,67.1C23.7,67.1,23.4,67.1,23.1,67.1z";
                var markPathSize = {width: 50, height: 70}
                var markOfCurrentDate = xLineDataPlan.append("g")
                    .attr("transform", "translate(" + (xDataPlan(statistics.dataUsageInfo.today) - markPathSize.width / 2) + ", " + (- markPathSize.height - 3) + ")");
                markOfCurrentDate.append("path")
                    .attr("class", "dataUsageMarkPath")
                    .attr("d", markPath);

                markOfCurrentDate.append("circle")
                    .attr("class", "dataUsageMarkHollow")
                    .attr("cx", 23.5)
                    .attr("cy", 24)
                    .attr("r", 21);

                markOfCurrentDate.append("text")
                    .attr("class", "dataUsageMarkText")
                    .attr("y", 26)
                    .attr("x", 23.5 )
                    .style("text-anchor", "middle")
                    .text(dateDataPlanFormatValue(statistics.dataUsageInfo.today));

                //////////////////////////////////////////////////
                /// Average used & expected used
                var xAverageUsed = xDataPlan(statistics.dataUsageInfo.today) - 5;
                var textDescriptionAverageUsed = xLineDataPlan.append("text")
                        .attr("class", "dataUsageMarkCaption")
                        .style("text-anchor", "start")
                        .attr("transform", "translate(" + xAverageUsed + ", 35)")
                        .text(scope.translation.AverageUsed);

                var bboxText = bboxOfElement(textDescriptionAverageUsed.node());


                var valueDataUsageAverageUsed = xLineDataPlan.append("text")
                        .attr("class", "dataUsageMarkValue")
                        .style("text-anchor", "start")
                        .attr("transform", "translate(" + xAverageUsed + ", 65)")
                        .text(commaFormat(statistics.dataUsageInfo.averageUsed.value.toFixed(1)));

                var bbox = bboxOfElement(valueDataUsageAverageUsed.node());

                var unitDataUsageAverageUsed = xLineDataPlan.append("text")
                   .attr( 'class', 'dataUsageMarkUnit' )
                   .style("text-anchor", "start")
                   .attr("transform", "translate(" + (xAverageUsed + bbox.width + 5) + ", 63)")
                   .text(statistics.dataUsageInfo.averageUsed.unit);

               var bboxUnit = bboxOfElement(unitDataUsageAverageUsed.node());

               var lineX = bbox.width + bboxUnit.width + 5 + 10;
               if (bboxText > bbox.width + bboxUnit.width) {
                   lineX  = bboxText +  5 + 10;
               }
               if (lineX < 80) {
                   lineX = 80;
               }

                var lineBetweenAverAndExpected = xLineDataPlan.append("line")
                    .attr("x1", xAverageUsed + lineX)
                    .attr("y1", 25)
                    .attr("x2", xAverageUsed + lineX)
                    .attr("y2", 80);

                var xExpectedUsed = xAverageUsed + lineX +10;

                var textDescriptionExpectedUsed = xLineDataPlan.append("text")
                        .attr("class", "dataUsageMarkCaption")
                        .style("text-anchor", "start")
                        .attr("transform", "translate(" + xExpectedUsed + ", 35)")
                        .text(scope.translation.ExpectedUsed);

                var valueDataUsageExpectedUsed = xLineDataPlan.append("text")
                        .attr("class", "dataUsageMarkValue")
                        .style("text-anchor", "start")
                        .attr("transform", "translate(" + xExpectedUsed + ", 65)")
                        .text(commaFormat(statistics.dataUsageInfo.expectedUsed.value.toFixed(1)));

                var bbox = bboxOfElement(valueDataUsageExpectedUsed.node());

                var unitDataUsageExpectedUsed = xLineDataPlan.append("text")
                   .attr( 'class', 'dataUsageMarkUnit' )
                   .style("text-anchor", "start")
                   .attr("transform", "translate(" + (xExpectedUsed + bbox.width + 5) + ", 63)")
                   .text(statistics.dataUsageInfo.expectedUsed.unit);

                //////////////////////////////////////////////////
                /// Edit plan
                var editPlanImage = xLineDataPlan.append("svg:image")
                    .attr("class", "dataUsageAlert-EditPlan")
                   .attr('width', 43)
                   .attr('height', 38)
                   .attr("xlink:href","/images/usage_monitor/icon_date.png")
                   .attr("transform", "translate(" + (xDataPlan(statistics.dataUsageInfo.dateRange.end) + 30) + ", " + (-40) + ")")
                   .on('click', function () {
                       console.log("showModal input!");

                       $("#divModalUsage").show();
                       $("#divModalDescriptionDialogUsage").dialog("open");

                   });

               var editPlanText = xLineDataPlan.append("text")
                   .attr("class", "dataUsageAlert-EditPlan dataUsageMarkUnit")
                   .style("text-anchor", "middle")
                   .attr("transform", "translate(" + (xDataPlan(statistics.dataUsageInfo.dateRange.end) + 30 + 43 / 2) + ", " + (-40 + 50) + ")")
                   .text(scope.translation.Plan)
                   .on('click', function () {
                       console.log("showModal input!");

                   });


                focusUpload.append("g")
                  .attr("class", "y axis")
                  .call(yAxis);

                var context = svg.append("g")
                    .attr("class", "context")
                    .attr("transform", "translate(" + marginBrush.left + "," + marginBrush.top + ")");

                barWidth = getStackBarWidthByBrushIndexes({begin:0, end:(data.length > 0 ? data.length - 1 : 0)});

                context.append("g")
                    .attr("class", "context")
                        .selectAll(".contextBar.stack")
                            .data(stackData)
                            .enter().append("g")
                            .attr("class", "contextBar stack")
                            .selectAll("rect")
                        .data(function(d) { return d; })
                            .enter().append("rect")
                            .attr("class", "contextBar")
                            .attr("width", barWidth)
                            .attr("transform", function(d) { return "translate(" + (x2(d.date) - barWidth / 2) + ",0)"; })
                            .attr("y", function(d) { return y2(d.y0 + d.y); })
                            .attr("height", function(d) { return y2(d.y0) - y2(d.y0 + d.y); })
                            .style("fill", function(d, i) { return color[i]; });

                dateTicksUpload = context.append("g")
                  .style('clip-path', 'url(#clip)')
                  .attr("class", "x axis")
                  .attr("transform", "translate(0," + height2 + ")")
                  .call(xAxis2)
                  .selectAll('.tick');

                removeOverlappingTicks(dateTicksUpload);

                var contextBrush = context.append("g")
                    .attr("class", "x brush")
                    .call(brush)
                .selectAll("rect")
                  .attr("y", -6)
                  .attr("height", height2 + 7);

                  if (detailContainer != null) {
                    detailContainer = context.append( 'g' );
                  }

                var bisectDate = d3.bisector(function(d) { return d.date; }).left;

                var gDetailUpload = svg.append("g")
                    .style("display", "none");

                // append the circle at the intersection
                gDetailUpload.append("circle")
                    .attr("class", "y lineChart--circleupload__highlighted")
                    .attr("r", 6);

                //////////////////////////////////////////////////
                /// Mouseover for SVG
                var svgMouseUpload = svg.append("rect")
                  .attr("id", "svgMouseUpload")
                  .attr("width", width)
                  .attr("height", height)
                  .style("fill", "none")
                  .style("pointer-events", "all")
                  .attr("transform", "translate(" + marginUpload.left + "," + marginUpload.top + ")")
                  .on("mouseover", function() { gDetailUpload.style("display", null); hideDetail(); })
                  .on("mouseout", function() { gDetailUpload.style("display", "none"); hideDetail(); })
                  .on("mousemove", function() {
                      var x0 = x.invert(d3.mouse(this)[0]),
                          i = bisectDate(data, x0, 1),
                          d0 = data[i - 1],
                          d1 = data[i],
                          d = x0 - d0.date > d1.date - x0 ? d1 : d0;

                      gDetailUpload.select("circle.y")
                          .attr("transform",
                                "translate(" + (x(d.date) + marginUpload.left) + "," +
                                               (y(d.rx) + marginUpload.top) + ")");

                      showDetail( d, this, marginUpload.top);

                  });

                  ///////////////////////////////////////////////
                  // Y axis descriptions
                  var dataDescription = svg.append("text")
                          .attr("transform", "rotate(-90)")
                          .attr("y", + 10)
                          .attr("x", - DETAIL_HEIGHT * 4 )
                          .attr("dy", "1em")
                          .style("text-anchor", "middle")
                          .text(scope.translation.Data + " (" + scope.unitUpload + ")");

                  ///////////////////////////////////////////////
                  // Legends: Upload
                  ///////////////////////////////////////////////

                  var uploadImage = svg.append("svg:image")
                     .attr('width', DATAImageSize.width)
                     .attr('height', DATAImageSize.height)
                     .attr("xlink:href","/images/usage_monitor/icon_upload.png");

                  var elementtxDesc = svg.append("text")
                     .attr("class", "dataUsageAlert-UploadCaption")
                     .style("text-anchor", "start")
                     .text(scope.translation.Upload);

                  var tx = valueAndUnitAdjusted(statistics.totaltx, scope.unitUpload);
                  var txDescription   = commaFormat(tx.value.toFixed(1));

                  var uploadValueElement = svg.append("text")
                     .attr( 'class', 'dataUsageAlert-UploadValue' )
                     .style("text-anchor", "start")
                     .text(txDescription);

                  var uploadUnitElement = svg.append("text")
                     .attr( 'class', 'dataUsageAlert-UploadUnit' )
                     .style("text-anchor", "start")
                     .text(tx.unit);

                 ///////////////////////////////////////////////
                 // Legends: Download
                 ///////////////////////////////////////////////
                 var downloadImage = svg.append("svg:image")
                    .attr('width', DATAImageSize.width)
                    .attr('height', DATAImageSize.height)
                    .attr("xlink:href","/images/usage_monitor/icon_download.png");

                 var elementrxDesc = svg.append("text")
                    .attr("class", "dataUsageAlert-DownloadCaption")
                    .style("text-anchor", "start")
                    .text(scope.translation.Download);

                 var rx = valueAndUnitAdjusted(statistics.totalrx, scope.unitDownload);
                 var rxDescription   = commaFormat(rx.value.toFixed(1));

                 var downloadValueElement = svg.append("text")
                    .attr( 'class', 'dataUsageAlert-DownloadValue' )
                    .style("text-anchor", "start")
                    .text(rxDescription);

                 var downloadUnitElement = svg.append("text")
                    .attr( 'class', 'dataUsageAlert-DownloadUnit' )
                    .style("text-anchor", "start")
                    .text(rx.unit);

                ///////////////////////////////////////////////
                // Legends: Total
                ///////////////////////////////////////////////
                var totalImage = svg.append("svg:image")
                   .attr('width', DATAImageSize.width)
                   .attr('height', DATAImageSize.height)
                   .attr("xlink:href","/images/usage_monitor/icon_data.png");

                var elementTotalDesc = svg.append("text")
                   .attr("class", "dataUsageAlert-TotalCaption")
                   .style("text-anchor", "start")
                   .text(scope.translation.Total);

                var totalValue = valueAndUnitAdjusted(statistics.totalrx + statistics.totaltx, scope.unitDownload);
                var totalDescription   = commaFormat(totalValue.value.toFixed(1));

                var totalValueElement = svg.append("text")
                   .attr( 'class', 'dataUsageAlert-TotalValue' )
                   .style("text-anchor", "start")
                   .text(totalDescription);

                var totalUnitElement = svg.append("text")
                   .attr( 'class', 'dataUsageAlert-TotalUnit' )
                   .style("text-anchor", "start")
                   .text(totalValue.unit);

                //////////////////////////////////////////////////
                /// Data usage alert panel
                if (rightDataAlertPanelWidth > 0) {
                    var demarcationLine = svg.append("line")
                                            .attr("class", "dataUsageAlert-Demarcation");
                    var tabSize =   {width: 130, height:30};
                    var tabOffset = {top: 5, right:15};
                    var limitOfTabWidth = tabSize.width - tabOffset.right;
                    var tabShadowHeight = 8;
                    var tabDataUsageAlert = svg.append("rect")
                                            .attr("class", "dataUsageAlert-Tab")
                                            .attr("width", 130)
                                            .attr("height", 30)
                                            .on('click', function () {
                                                showDataUsage = !showDataUsage;
                                                toggleDataUsageAlert(true);
                                            });

                    var tabShadowDataUsageAlert = svg.append("path")
                        .attr("class", "dataUsageAlert-TabShadow");

                    var tabTitle = svg.append("text")
                            .attr("class", "dataUsageAlert-TabTitle")
                            .style("text-anchor", "middle")
                            .on('click', function () {
                                showDataUsage = !showDataUsage;
                                toggleDataUsageAlert(true);
                            });

                    //////////////////////////////////////////////////
                    /// Show waterDrop
                    var waterDrop = new WaterDrop(svg);

                    waterDrop.appendToElement(svg);
                    console.log("fill to index :" + statistics.dataUsageInfo.waterDropIndex);
                    var waterLineY = waterDrop.fillToIndex(statistics.dataUsageInfo.waterDropIndex);

                    //////////////////////////////////////////////////
                    /// Show Total
                    var textDescriptionDataUsageTotal = svg.append("text")
                            .attr("class", "dataUsageAlert-TotalCaption")
                            .style("text-anchor", "start")
                            .text(scope.translation.DataUsage);

                    fitTextToSize(textDescriptionDataUsageTotal, limitOfTabWidth)

                    var valueDataUsageTotal = svg.append("text")
                            .attr("class", "dataUsageAlert-TotalValue")
                            .style("text-anchor", "start")
                            .text(commaFormat(statistics.dataUsageInfo.currentDataUsage.value.toFixed(1)));

                    var unitDataUsageTotal = svg.append("text")
                       .attr( 'class', 'dataUsageAlert-TotalUnit' )
                       .style("text-anchor", "start")
                       .text(trimUnit(statistics.dataUsageInfo.currentDataUsage.unit));

                   //////////////////////////////////////////////////
                   /// Show Remaining
                   var textDescriptionDataUsageRemaining = svg.append("text")
                           .attr("class", "dataUsageAlert-TotalCaption")
                           .style("text-anchor", "start")
                           .text(scope.translation.Remaining);

                   var textValueRemaining = "∞";
                   if (statistics.dataUsageInfo.quotaUsage.value > 0) {
                       textValueRemaining = commaFormat(statistics.dataUsageInfo.remainingDataUsage.value.toFixed(1));
                   }

                   var valueDataUsageRemaining = svg.append("text")
                           .attr("class", "dataUsageAlert-TotalValue")
                           .style("text-anchor", "start")
                           .text(textValueRemaining)

                   var unitDataUsageRemaining = svg.append("text")
                      .attr( 'class', 'dataUsageAlert-TotalUnit' )
                      .style("text-anchor", "start")
                      .text(trimUnit(statistics.dataUsageInfo.remainingDataUsage.unit));

                  //////////////////////////////////////////////////
                  /// Show Days left
                  var textDescriptionDataUsageDaysLeft = svg.append("text")
                          .attr("class", "dataUsageAlert-TotalCaption")
                          .style("text-anchor", "start")
                          .text(scope.translation.DaysLeft);

                  var valueDataUsageDaysLeft = svg.append("text")
                          .attr("class", "dataUsageAlert-TotalValue")
                          .style("text-anchor", "start")
                          .text(statistics.dataUsageInfo.daysLeft);

                  var unitDataUsageDaysLeft = svg.append("text")
                     .attr( 'class', 'dataUsageAlert-TotalUnit' )
                     .style("text-anchor", "start")
                     .text(scope.translation.Days);

                 //////////////////////////////////////////////////
                 /// Remaining Line
                 var remainingLine = svg.append("line")
                                         .attr("class", "dataUsageAlert-Demarcation");

                //  var dialogGroup = svg.append("g")
                //                      .attr("transform", "translate(0," + (height + height2 + 245 ) + ")");

                 toggleDataUsageAlert(false);
            } // if (rightDataAlertPanelWidth > 0) , show Panel

            function trimUnit(unit) {
              if (unit == null) {
                return "";
              }
              if (unit.length == 5) {
                return unit.substring(0, 2);
              }
              return unit.substring(0, 1);
            }

            function toggleDataUsageAlert(showAnimation) {

                if (showDataUsage) {

                    //////////////////////////////////////////////////
                    /// Upload
                    var marginText = 5;
                    var iconPos = {
                        x: (svgBoundingBox.width - rightDataAlertPanelWidth) / 2 - DATAImageSize.width * 2 + 50,
                        y: marginBrush.bottom + DETAIL_HEIGHT * 2
                    };

                    uploadImage.transition()
                        .attr('x', iconPos.x)
                        .attr('y', iconPos.y);

                    elementtxDesc.transition()
                        .attr("x", iconPos.x + DATAImageSize.width + marginText)
                        .attr("y", iconPos.y + 10);

                    var dxlegend = bboxOfElement(elementtxDesc.node()).x + bboxOfElement(elementtxDesc.node()).width + 10;

                    var uploadValuePos = {
                        x: iconPos.x + DATAImageSize.width + marginText,
                        y: marginBrush.bottom + DETAIL_HEIGHT * 2 + DATAImageSize.height - 5
                    };

                    uploadValueElement
                        .attr("x", uploadValuePos.x)
                        .attr("y", uploadValuePos.y);

                    dxlegend = bboxOfElement(uploadValueElement.node()).x + bboxOfElement(uploadValueElement.node()).width + 10;

                    var uploadUnitPos = {
                        x: dxlegend,
                        y: marginBrush.bottom + DETAIL_HEIGHT * 2 + DATAImageSize.height - 5
                    };

                    uploadUnitElement.transition()
                        .attr("x", uploadUnitPos.x)
                        .attr("y", uploadUnitPos.y);

                    ///////////////////////////////////////////////
                    // Legends: Download
                    ///////////////////////////////////////////////
                    var iconPos = {
                        x: (svgBoundingBox.width - rightDataAlertPanelWidth) / 2 + DATAImageSize.width * 2 + 50,
                        y: marginBrush.bottom + DETAIL_HEIGHT * 2
                    };

                    downloadImage.transition()
                        .attr('x', iconPos.x)
                        .attr('y', iconPos.y);

                    elementrxDesc.transition()
                        .attr("x", iconPos.x + DATAImageSize.width + marginText)
                        .attr("y", iconPos.y + 10);

                    var dxlegend = bboxOfElement(elementrxDesc.node()).x + bboxOfElement(elementrxDesc.node()).width + 10;
                    var downloadValuePos = {
                        x: iconPos.x + DATAImageSize.width + marginText,
                        y: marginBrush.bottom + DETAIL_HEIGHT * 2 + DATAImageSize.height - 5
                    };

                    downloadValueElement
                        .attr("x", downloadValuePos.x)
                        .attr("y", downloadValuePos.y);

                    dxlegend = bboxOfElement(downloadValueElement.node()).x + bboxOfElement(downloadValueElement.node()).width + 10;
                    var downloadUnitPos = {
                        x: dxlegend,
                        y: marginBrush.bottom + DETAIL_HEIGHT * 2 + DATAImageSize.height - 5
                    };

                    downloadUnitElement.transition()
                        .attr("x", downloadUnitPos.x)
                        .attr("y", downloadUnitPos.y);

                    ///////////////////////////////////////////////
                    // Legends: Total
                    ///////////////////////////////////////////////
                    var iconPos = {
                        x: (svgBoundingBox.width - rightDataAlertPanelWidth) / 2 - DATAImageSize.width * 6 + 50,
                        y: marginBrush.bottom + DETAIL_HEIGHT * 2
                    };

                    totalImage.transition()
                        .attr('x', iconPos.x)
                        .attr('y', iconPos.y);

                    elementTotalDesc.transition()
                        .attr("x", iconPos.x + DATAImageSize.width + marginText)
                        .attr("y", iconPos.y + 10);

                    var dxlegend = bboxOfElement(elementTotalDesc.node()).x + bboxOfElement(elementTotalDesc.node()).width + 10;
                    var totalValuePos = {
                        x: iconPos.x + DATAImageSize.width + marginText,
                        y: marginBrush.bottom + DETAIL_HEIGHT * 2 + DATAImageSize.height - 5
                    };

                    totalValueElement
                        .attr("x", totalValuePos.x)
                        .attr("y", totalValuePos.y);

                    dxlegend = bboxOfElement(totalValueElement.node()).x + bboxOfElement(totalValueElement.node()).width + 10;
                    var totalUnitPos = {
                        x: dxlegend,
                        y: marginBrush.bottom + DETAIL_HEIGHT * 2 + DATAImageSize.height - 5
                    };

                    totalUnitElement.transition()
                        .attr("x", totalUnitPos.x)
                        .attr("y", totalUnitPos.y);

                    //////////////////////////////////////////////////
                    /// Data usage related
                    remainingLine.transition()
                        .attr("x1", svgBoundingBox.width - rightDataAlertPanelWidth)
                        .attr("y1", 0)
                        .attr("x2", svgBoundingBox.width - rightDataAlertPanelWidth)
                        .attr("y2", 0);

                    demarcationLine.transition()
                        .attr("x1", svgBoundingBox.width - rightDataAlertPanelWidth)
                        .attr("y1", 0)
                        .attr("x2", svgBoundingBox.width - rightDataAlertPanelWidth)
                        .attr("y2", SVGHeight);

                    tabDataUsageAlert.transition()
                        .attr("x", svgBoundingBox.width - rightDataAlertPanelWidth - tabOffset.right)
                        .attr("y", tabOffset.top);

                    tabShadowDataUsageAlert.transition()
                        .attr("d", "M " + (svgBoundingBox.width - rightDataAlertPanelWidth - tabOffset.right) + " " + (tabOffset.top + tabSize.height) +
                            " L " + (svgBoundingBox.width - rightDataAlertPanelWidth) + " " + (tabOffset.top + tabSize.height) +
                            " L " + (svgBoundingBox.width - rightDataAlertPanelWidth) + " " + (tabOffset.top + tabSize.height + tabShadowHeight) + " Z")

                    tabTitle.transition()
                        .attr("x", svgBoundingBox.width - rightDataAlertPanelWidth - tabOffset.right + tabSize.width / 2)
                        .attr("y", tabOffset.top + tabSize.height / 2 + 5)
                        .text(scope.translation.DataUsage)
                        .each( 'end', function() {
                          fitTextToSize(tabTitle, bboxOfElement(tabDataUsageAlert.node()).width);
                        });


                    //////////////////////////////////////////////////
                    /// WaterDrop & Data alert
                    waterDrop.transform("translate(" + (svgBoundingBox.width - rightDataAlertPanelWidth + 10) + ", " + (tabOffset.top + 50) + ")scale(" + (rightDataAlertPanelWidth / 300 * 0.5) + ")", showAnimation);

                    //////////////////////////////////////////////////
                    /// Show Total
                    textDescriptionDataUsageTotal.transition()
                        .attr("x", svgBoundingBox.width - rightDataAlertPanelWidth + 5)
                        .attr("y", tabOffset.top + 130);

                    valueDataUsageTotal
                        .attr("x", svgBoundingBox.width - rightDataAlertPanelWidth + 8)
                        .attr("y", tabOffset.top + 165);

                    var dxlegend = bboxOfElement(valueDataUsageTotal.node()).x + bboxOfElement(valueDataUsageTotal.node()).width + 5;
                    var uitDataUsagePos = {
                        x: dxlegend,
                        y: tabOffset.top + 165
                    };

                    unitDataUsageTotal.transition()
                        .attr("x", uitDataUsagePos.x)
                        .attr("y", uitDataUsagePos.y);

                    //////////////////////////////////////////////////
                    /// Show Remaining
                    textDescriptionDataUsageRemaining.transition()
                        .style("text-anchor", "start")
                        .attr("x", svgBoundingBox.width - rightDataAlertPanelWidth + 15)
                        .attr("y", tabOffset.top + 205);

                    valueDataUsageRemaining
                        .style("text-anchor", "start")
                        .attr("x", svgBoundingBox.width - rightDataAlertPanelWidth + 13)
                        .attr("y", tabOffset.top + 240);

                    var dxlegend = bboxOfElement(valueDataUsageRemaining.node()).x + bboxOfElement(valueDataUsageRemaining.node()).width + 5;
                    var uitDataUsagePos = {
                        x: dxlegend,
                        y: tabOffset.top + 240
                    };

                    unitDataUsageRemaining.transition()
                        .style("text-anchor", "start")
                        .attr("x", uitDataUsagePos.x)
                        .attr("y", uitDataUsagePos.y);

                    //////////////////////////////////////////////////
                    /// Show Days left
                    textDescriptionDataUsageDaysLeft.transition()
                        .style("text-anchor", "start")
                        .attr("x", svgBoundingBox.width - rightDataAlertPanelWidth + 20)
                        .attr("y", tabOffset.top + 280);

                    valueDataUsageDaysLeft
                        .style("text-anchor", "start")
                        .attr("x", svgBoundingBox.width - rightDataAlertPanelWidth + 18)
                        .attr("y", tabOffset.top + 315);

                    var dxlegend = bboxOfElement(valueDataUsageDaysLeft.node()).x + bboxOfElement(valueDataUsageDaysLeft.node()).width + 5;
                    var uitDataUsagePos = {
                        x: dxlegend,
                        y: tabOffset.top + 315
                    };

                    unitDataUsageDaysLeft.transition()
                        .style("text-anchor", "start")
                        .attr("x", uitDataUsagePos.x)
                        .attr("y", uitDataUsagePos.y);

                    //////////////////////////////////////////////////
                    /// data usage history
                    focusUpload.transition()
                        .style("opacity", "1.0");

                    context.transition()
                        .style("opacity", "1.0");

                    dataDescription.transition()
                        .style("opacity", "1.0");

                    svgMouseUpload.attr("height", height)
                    contextBrush.attr("height", height2 + 7);

                    if (showAnimation) {
                        xLineDataPlan.transition()
                            .style("opacity", "0.0");
                    } else {
                        xLineDataPlan
                            .style("opacity", "0.0");
                    }
                }

                //////////////////////////////////////////////////
                /// Show Usage Alert
                else {

                    //////////////////////////////////////////////////
                    /// Data Usage Alert
                    demarcationLine.transition()
                        .attr("x1", rightDataAlertPanelWidth)
                        .attr("y1", 0)
                        .attr("x2", rightDataAlertPanelWidth)
                        .attr("y2", SVGHeight);

                    tabDataUsageAlert.transition()
                        .attr("x", tabOffset.right + 10)
                        .attr("y", tabOffset.top)

                    tabShadowDataUsageAlert.transition()
                        .attr("d", "M " + (tabOffset.right + 10 + tabSize.width) + " " + (tabOffset.top + tabSize.height) +
                            " L " + (10 + tabSize.width) + " " + (tabOffset.top + tabSize.height) +
                            " L " + (10 + tabSize.width) + " " + (tabOffset.top + tabSize.height + tabShadowHeight) + " Z")

                    tabTitle.transition()
                        .attr("x", tabOffset.right + 10 + tabSize.width / 2 )
                        .attr("y", tabOffset.top + tabSize.height / 2 + 5)
                        .text(scope.translation.DataHistory)
                        .each( 'end', function() {
                          fitTextToSize(tabTitle, bboxOfElement(tabDataUsageAlert.node()).width);
                        });

                    remainingLine.transition()
                        .attr("x1", (svgBoundingBox.width - rightDataAlertPanelWidth) / 2 + 200)
                        .attr("y1", tabOffset.top + 60 + waterLineY)
                        .attr("x2", (svgBoundingBox.width - rightDataAlertPanelWidth) / 2 + 320)
                        .attr("y2", tabOffset.top + 60 + waterLineY);

                    ///////////////////////////////////////////////
                    // Legends: Total
                    ///////////////////////////////////////////////
                    var marginText = 5;
                    var marginImage = 5;
                    var iconPos = {
                        x: marginImage,
                        y: tabOffset.top + tabSize.height + DETAIL_HEIGHT
                    };

                    totalImage.transition()
                        .attr('x', iconPos.x)
                        .attr('y', iconPos.y);

                    elementTotalDesc.transition()
                        .attr("x", iconPos.x + DATAImageSize.width + marginText)
                        .attr("y", iconPos.y + DATAImageSize.height - 5);

                    var dxlegend = bboxOfElement(elementTotalDesc.node()).x + bboxOfElement(elementTotalDesc.node()).width + 10;
                    var totalValuePos = {
                        x: iconPos.x,
                        y: iconPos.y + DATAImageSize.height * 1.7 + marginText
                    };

                    totalValueElement
                        .attr("x", totalValuePos.x)
                        .attr("y", totalValuePos.y);

                    dxlegend = bboxOfElement(totalValueElement.node()).x + bboxOfElement(totalValueElement.node()).width + 10;
                    var totalUnitPos = {
                        x: dxlegend,
                        y: totalValuePos.y
                    };

                    totalUnitElement.transition()
                        .attr("x", totalUnitPos.x)
                        .attr("y", totalUnitPos.y);

                    //////////////////////////////////////////////////
                    /// Upload
                    var iconPos = {
                        x: iconPos.x,
                        y: iconPos.y + DETAIL_HEIGHT * 4.5
                    };

                    uploadImage.transition()
                        .attr('x', iconPos.x)
                        .attr('y', iconPos.y);

                    elementtxDesc.transition()
                        .attr("x", iconPos.x + DATAImageSize.width + marginText)
                        .attr("y", iconPos.y + DATAImageSize.height - 10);

                    var dxlegend = bboxOfElement(elementtxDesc.node()).x + bboxOfElement(elementtxDesc.node()).width + 10;

                    var uploadValuePos = {
                        x: iconPos.x,
                        y: iconPos.y + DATAImageSize.height * 1.4 + marginText
                    };

                    uploadValueElement
                        .attr("x", uploadValuePos.x)
                        .attr("y", uploadValuePos.y);

                    dxlegend = bboxOfElement(uploadValueElement.node()).x + bboxOfElement(uploadValueElement.node()).width + 10;

                    var uploadUnitPos = {
                        x: dxlegend,
                        y: uploadValuePos.y
                    };

                    uploadUnitElement.transition()
                        .attr("x", uploadUnitPos.x)
                        .attr("y", uploadUnitPos.y);

                    ///////////////////////////////////////////////
                    // Legends: Download
                    ///////////////////////////////////////////////
                    var iconPos = {
                        x: iconPos.x,
                        y: iconPos.y + DETAIL_HEIGHT * 4
                    };

                    downloadImage.transition()
                        .attr('x', iconPos.x)
                        .attr('y', iconPos.y);

                    elementrxDesc.transition()
                        .attr("x", iconPos.x + DATAImageSize.width + marginText)
                        .attr("y", iconPos.y + DATAImageSize.height - 10);

                    var dxlegend = bboxOfElement(elementrxDesc.node()).x + bboxOfElement(elementrxDesc.node()).width + 10;
                    var downloadValuePos = {
                        x: iconPos.x,
                        y: iconPos.y + DATAImageSize.height * 1.4 + marginText
                    };

                    downloadValueElement
                        .attr("x", downloadValuePos.x)
                        .attr("y", downloadValuePos.y);

                    dxlegend = bboxOfElement(downloadValueElement.node()).x + bboxOfElement(downloadValueElement.node()).width + 10;
                    var downloadUnitPos = {
                        x: dxlegend,
                        y: downloadValuePos.y
                    };

                    downloadUnitElement.transition()
                        .attr("x", downloadUnitPos.x)
                        .attr("y", downloadUnitPos.y);

                    //////////////////////////////////////////////////
                    /// WaterDrop & Data alert
                    waterDrop.transform("translate(" + ((svgBoundingBox.width - rightDataAlertPanelWidth) / 2) + ", " + (tabOffset.top + 60) + ")scale(1)", showAnimation);

                    //////////////////////////////////////////////////
                    /// Show Total
                    textDescriptionDataUsageTotal.transition()
                        .attr("x", (svgBoundingBox.width - rightDataAlertPanelWidth) / 2 - 120)
                        .attr("y", tabOffset.top + 60);

                    valueDataUsageTotal
                        .attr("x", (svgBoundingBox.width - rightDataAlertPanelWidth) / 2 - 120)
                        .attr("y", tabOffset.top + 100);

                    var dxlegend = bboxOfElement(valueDataUsageTotal.node()).x + bboxOfElement(valueDataUsageTotal.node()).width + 5;
                    var uitDataUsagePos = {
                        x: dxlegend,
                        y: tabOffset.top + 100
                    };

                    unitDataUsageTotal.transition()
                        .attr("x", uitDataUsagePos.x)
                        .attr("y", uitDataUsagePos.y);

                    //////////////////////////////////////////////////
                    /// Show Remaining
                    unitDataUsageRemaining
                        .style("text-anchor", "end")
                        .attr("x", (svgBoundingBox.width - rightDataAlertPanelWidth) / 2 + 320)
                        .attr("y", tabOffset.top + 60 + waterLineY - 15);

                    var dxlegend = bboxOfElement(unitDataUsageRemaining.node()).x - 5;
                    var pos = {
                        x: dxlegend,
                        y: tabOffset.top + 60 + waterLineY - 15
                    };

                    valueDataUsageRemaining
                        .style("text-anchor", "end")
                        .attr("x", pos.x)
                        .attr("y", pos.y);

                    var dxlegend = bboxOfElement(valueDataUsageRemaining.node()).x;
                    var pos = {
                        x: dxlegend,
                        y: tabOffset.top + 60 + waterLineY - 50
                    };

                    textDescriptionDataUsageRemaining.transition()
                        .style("text-anchor", "start")
                        .attr("x", pos.x)
                        .attr("y", pos.y);

                    //////////////////////////////////////////////////
                    /// Show Days left
                    unitDataUsageDaysLeft
                        .style("text-anchor", "end")
                        .attr("x", (svgBoundingBox.width - rightDataAlertPanelWidth) / 2 + 320)
                        .attr("y", tabOffset.top + 60 + waterLineY + 50);

                    var dxlegend = bboxOfElement(unitDataUsageDaysLeft.node()).x - 5;
                    var pos = {
                        x: dxlegend,
                        y: tabOffset.top + 60 + waterLineY + 50
                    };

                    valueDataUsageDaysLeft
                        .style("text-anchor", "end")
                        .attr("x", pos.x)
                        .attr("y", pos.y);

                    var dxlegend = bboxOfElement(valueDataUsageDaysLeft.node()).x;
                    var pos = {
                        x: dxlegend,
                        y: tabOffset.top + 60 + waterLineY + 15
                    };

                    textDescriptionDataUsageDaysLeft.transition()
                        .style("text-anchor", "start")
                        .attr("x", pos.x)
                        .attr("y", pos.y);

                    //////////////////////////////////////////////////
                    /// data usage history
                    focusUpload.transition()
                        .style("opacity", "0.0");

                    context.transition()
                        .style("opacity", "0.0");

                    dataDescription.transition()
                        .style("opacity", "0.0");

                    svgMouseUpload.attr("height", 0)
                    contextBrush.attr("height", 0);

                    if (showAnimation) {
                        xLineDataPlan.transition()
                            .style("opacity", "1.0");
                    } else {
                        xLineDataPlan
                            .style("opacity", "1.0");
                    }

                }

            } // function showDataUsageAlert()

            function getStackBarWidthByBrushIndexes(brushIndex) {
                if (brushIndex == null ||
                    brushIndex.begin == null || brushIndex.end == null ||
                    (brushIndex.begin >= brushIndex.end)) {
                    return 1;
                }
                var barWidth = width / (brushIndex.end  - brushIndex.begin) / 2;

                if (barWidth < 1) {
                    barWidth = 1;
                }
                return barWidth;
            }

            function changeSummarizeStatistics(statistics) {

                if (statistics == null ||
                    uploadValueElement == null || downloadValueElement == null ||
                    downloadValueElement == null || downloadUnitElement == null) {
                    return;
                }

                var tx = valueAndUnitAdjusted(statistics.totaltx, scope.unitUpload);
                var txDescription   = commaFormat(tx.value.toFixed(1));

                uploadValueElement.text(txDescription);

                var dxlegend = bboxOfElement(uploadValueElement.node()).x + bboxOfElement(uploadValueElement.node()).width + 10;

                var uploadUnitPos = { x: dxlegend , y: marginBrush.bottom + DETAIL_HEIGHT * 2 + DATAImageSize.height - 5 };

                uploadUnitElement.attr("x", uploadUnitPos.x )
                   .attr("y", uploadUnitPos.y )
                   .text(tx.unit);

               var rx = valueAndUnitAdjusted(statistics.totalrx, scope.unitDownload);
               var rxDescription   = commaFormat(rx.value.toFixed(1));

               downloadValueElement.text(rxDescription);

               var dxlegend = bboxOfElement(downloadValueElement.node()).x + bboxOfElement(downloadValueElement.node()).width + 10;

               var downloadUnitPos = { x: dxlegend , y: marginBrush.bottom + DETAIL_HEIGHT * 2 + DATAImageSize.height - 5 };

               downloadUnitElement.attr("x", downloadUnitPos.x )
                  .attr("y", downloadUnitPos.y )
                  .text(rx.unit);

               var totalx = valueAndUnitAdjusted(statistics.totaltx + statistics.totalrx, scope.unitDownload);
               var totalDescription   = commaFormat(totalx.value.toFixed(1));

               totalValueElement.text(totalDescription);

               var dxlegend = bboxOfElement(totalValueElement.node()).x + bboxOfElement(totalValueElement.node()).width + 10;

               var totalUnitPos = { x: dxlegend , y: marginBrush.bottom + DETAIL_HEIGHT * 2 + DATAImageSize.height - 5 };

               totalUnitElement.attr("x", totalUnitPos.x )
                  .attr("y", totalUnitPos.y )
                  .text(totalx.unit);
            }

            function converToIndexWithCurrentRange(currentRange) {
                var resultIndexes = {begin:0, end:0};

                if (currentRange == null) {
                    return resultIndexes;
                }

                for (var index in data) {
                    if (data[index].date >= currentRange[0]) {
                        resultIndexes.begin = parseInt(index);
                        break;
                    }
                }

                for (var index = data.length -1; index >= 0; --index) {
                    if (data[index].date <= currentRange[1]) {
                        resultIndexes.end = index;
                        break;
                    }
                }

                return resultIndexes;
            }

            function statisticsFromData() {
                var numValidDays = 0;
                var totaltx = 0;
                var totalrx = 0;
                var avearagetx = 0;
                var avearagerx = 0;
                var maxrx = 0;
                var maxtx = 0;
                var waterRatio =  1;
                if (scope.dataUsageInfo.quotaUsage > 1) {
                    waterRatio = (scope.dataUsageInfo.currentDataUsage >= scope.dataUsageInfo.quotaUsage ? 0 : (scope.dataUsageInfo.quotaUsage - scope.dataUsageInfo.currentDataUsage) / (scope.dataUsageInfo.quotaUsage) ) ;
                }
                var dataUsageInfo = {
                    currentDataUsage:  valueAndUnitAdjusted(scope.dataUsageInfo.currentDataUsage, "Byte"),
                    remainingDataUsage: valueAndUnitAdjusted((scope.dataUsageInfo.quotaUsage - scope.dataUsageInfo.currentDataUsage < 0 ? 0 : scope.dataUsageInfo.quotaUsage - scope.dataUsageInfo.currentDataUsage), "Byte"),
                    quotaUsage: valueAndUnitAdjusted(scope.dataUsageInfo.quotaUsage, "Byte"),
                    waterDropIndex : 13 - Math.ceil(waterRatio * 13),
                    warningThreshold: scope.dataUsageInfo.warningThreshold,
                    averageUsed:  valueAndUnitAdjusted((scope.dataUsageInfo.pastDays == 0 ? scope.dataUsageInfo.currentDataUsage : scope.dataUsageInfo.currentDataUsage / scope.dataUsageInfo.pastDays), "Byte"),
                    expectedUsed:  valueAndUnitAdjusted(scope.dataUsageInfo.currentDataUsage / (scope.dataUsageInfo.pastDays == 0 ? 1 : scope.dataUsageInfo.pastDays ) * scope.dataUsageInfo.remainingDays + scope.dataUsageInfo.currentDataUsage, "Byte"),
                    daysLeft : scope.dataUsageInfo.remainingDays,
                    dateRange: scope.dataUsageInfo.dateRange,
                    today: scope.dataUsageInfo.today
                };

                for (var index in data) {
                    if (scope.initialBrushIndex.end >= index && index >= scope.initialBrushIndex.begin) {
                        if (data[index].rx > 0 || data[index].tx > 0) {
                            ++numValidDays;
                            totaltx += data[index].tx;
                            totalrx += data[index].rx;
                            if (maxrx < data[index].rx) {
                                maxrx = data[index].rx;
                            }
                            if (maxtx < data[index].tx) {
                                maxtx = data[index].tx;
                            }
                        }
                    }
                }

                if (numValidDays > 0) {
                  avearagetx = totaltx / numValidDays;
                  avearagerx = totalrx / numValidDays;
                }

                return {
                    numValidDays : numValidDays,
                    totaltx : totaltx,
                    totalrx : totalrx,
                    avearagetx : avearagetx,
                    avearagerx : avearagerx,
                    maxrx : maxrx,
                    maxtx : maxtx,
                    dataUsageInfo : dataUsageInfo
                };

            }

            function brushed() {

                var currentRange = (brush.empty()? undefined : brush.extent());
                scope.initialBrushIndex = converToIndexWithCurrentRange(currentRange);
                changeSummarizeStatistics(statisticsFromData());

                x.domain(brush.empty() ? x2.domain() : brush.extent());
                var barWidth = getStackBarWidthByBrushIndexes(scope.initialBrushIndex);

                focusUpload.selectAll(".unitBar")
                           .attr("width", barWidth)
                           .attr("transform", function(d) { return "translate(" + (x(d.date) - barWidth / 2) + ",0)"; });

                var ticks = focusUpload.select(".x.axis").call(xAxis).selectAll('.tick');
                removeOverlappingTicks(ticks);


            } // function brushed

            function tween( b, callback ) {
              return function( a ) {
                var i = d3.interpolateArray( a, b );
                return function( t ) {
                  return callback( i ( t ) );
                };
              };
          } // function tween

            function removeOverlappingTicks(ticks) {
                if (ticks == null) {
                    return;
                }
                for (var j = 0; j < ticks[0].length; j++) {
                    var c = ticks[0][j],
                        n = ticks[0][j + 1];
                    if (!c || !n || !c.getBoundingClientRect || !n.getBoundingClientRect)
                        continue;
                    while (c.getBoundingClientRect().right > n.getBoundingClientRect().left) {
                        d3.select(n).remove();
                        j++;
                        n = ticks[0][j + 1];
                        if (!n)
                            break;
                    }
                }
            } // function removeOverlappingTicks(ticks) {


            function showDetail(d, element, yOffset) {

                if (scope.enabled == false) {
                    return;
                }

                if (scope.initialBrushIndex.end < d.x || d.x < scope.initialBrushIndex.begin) {
                    gDetailUpload.style("display", "none");
                    return;
                }

                gDetailUpload.style("display", null);

                d3.selectAll(".bubble_tooltip").remove();

                // console.log("yOffset: " + yOffset);

                var boundingBox = {
                    x: x(d.date),
                    y: 10,
                    height: height - 50,
                    width: 0
                };

                var boundingBoxCTM = element.getCTM();

                boundingBoxCTM.a = 1;
                boundingBoxCTM.b = 0;
                boundingBoxCTM.c = 0;
                boundingBoxCTM.d = 1;
                boundingBoxCTM.e = 0;
                boundingBoxCTM.f = 0;

                // console.log("boundingBox: ");
                // console.log(boundingBox);

                boundingBox.y = 50;
                boundingBox.height = height - 50;

                var tooltip = detailContainer.append('path')
                    .attr("class", (d.tx >= d.rx ? "bubble_tooltipPathUpload" : "bubble_tooltipPathDownload") + " bubble_tooltip")
                    // .attr('d', 'M0,40 L0,5 Q0,0 5,0 L150,0 Q155,0 155,5 L155,65 Q155,70 150,70 L85,70 L77,80 L69,70 L5,70 Q0,70 0,65 L0,40')
                    // .attr("transform", "scale(1.0)translate(" + ( boundingBox.x + boundingBox.width ) + ", " + ( boundingBox.y + boundingBox.height ) + ")")
                    // .attr("transform", "scale(1.0)translate(" + ( boundingBox.x - boundingBox.width / 2 ) + ", " + ( 0 ) + ")")
                ;

                var svgBoundingBox = bboxOfElement(d3.select("#svgMouseUpload").node());

                // console.log("svgBoundingBox: ");
                // console.log(svgBoundingBox);

                var topAvailable = boundingBox.y - svgBoundingBox.y;
                var bottomAvailable = svgBoundingBox.height - boundingBox.height - boundingBox.y;

                var leftAvailable = boundingBox.x - svgBoundingBox.x;
                var rightAvailable = svgBoundingBox.width - boundingBox.width - boundingBox.x;

                // console.log("topAvailable: " + topAvailable);
                // console.log("bottomAvailable: " + bottomAvailable);
                // console.log("leftAvailable: " + leftAvailable);
                // console.log("rightAvailable: " + rightAvailable);

                var tooltipPointUpDownWidth = 155;
                var tooltipPointUpDownHeight = 80;

                var tooltipPointLeftRightWidth = 165;
                var tooltipPointLeftRightHeight = 70;

                var marginUpload = 5;

                var pathPoints = 'M0,40 L0,5 Q0,0 5,0 L150,0 Q155,0 155,5 L155,65 Q155,70 150,70 L85,70 L77,80 L69,70 L5,70 Q0,70 0,65 L0,40'; // points down
                // boundingBoxCTM = boundingBoxCTM.translate(boundingBox.x - tooltipPointUpDownWidth / 2 + boundingBox.width / 2, boundingBox.y - tooltipPointUpDownHeight - marginUpload);

                var pathCTM = boundingBoxCTM.translate(boundingBox.x - tooltipPointUpDownWidth / 2 + boundingBox.width / 2, boundingBox.y - tooltipPointUpDownHeight - marginUpload + yOffset);
                var textCTM = boundingBoxCTM.translate(boundingBox.x - tooltipPointUpDownWidth / 2 + boundingBox.width / 2, boundingBox.y - tooltipPointUpDownHeight - marginUpload + yOffset);
                if (topAvailable > tooltipPointUpDownHeight + marginUpload && leftAvailable > tooltipPointUpDownWidth / 2 && rightAvailable > tooltipPointUpDownWidth / 2) {
                    // console.log("show on top");
                } else if (bottomAvailable > tooltipPointUpDownHeight + marginUpload && leftAvailable > tooltipPointUpDownWidth / 2 && rightAvailable > tooltipPointUpDownWidth / 2) {
                    // console.log("show on bottom");
                    // translate(" + ( boundingBox.x - tooltipPointUpDownWidth / 2 ) + ", " + ( boundingBox.y + boundingBox.height ) + ")"
                    // stringOfTooltipTextTransform = "translate(" + ( boundingBox.x + boundingBox.width / 2) + ", " + ( boundingBox.y + boundingBox.height + marginUpload * 3.5 ) + ")";
                    // stringOfPathTransform = "translate(" + ( boundingBox.x - tooltipPointUpDownWidth / 2 + boundingBox.width / 2) + ", " + ( boundingBox.y + boundingBox.height + tooltipPointUpDownHeight + marginUpload ) + ")scale(1,-1)";
                } else if (rightAvailable > tooltipPointLeftRightWidth + marginUpload) {
                    // console.log("show on right");
                    pathPoints = 'M10,17 L10,5 Q10,0 15,0 L160,0 Q165,0 165,5 L165,65 Q165,70 160,70 L15,70 Q10,70 10,65 L10,43 L0,35 L10,27 L10,17';
                    pathCTM = boundingBoxCTM.translate(boundingBox.x + boundingBox.width + marginUpload, marginUpload * 3  + yOffset);
                    textCTM = boundingBoxCTM.translate(boundingBox.x + boundingBox.width, marginUpload * 3  + yOffset); //tooltipPointLeftRightHeight
                    // stringOfTooltipTextTransform = "translate(" + ( boundingBox.x + boundingBox.width + tooltipPointLeftRightWidth / 2 ) + ", " + ( boundingBox.y - tooltipPointLeftRightHeight / 2 + boundingBox.height / 2 + marginUpload * 2) + ")";
                    // stringOfPathTransform = "translate(" + ( boundingBox.x + boundingBox.width ) + ", " + ( boundingBox.y - tooltipPointLeftRightHeight / 2 + boundingBox.height / 2  ) + ")";
                } else if (leftAvailable > tooltipPointLeftRightWidth + marginUpload) {
                    // console.log("show on left");
                    pathPoints = 'M10,17 L10,5 Q10,0 15,0 L160,0 Q165,0 165,5 L165,65 Q165,70 160,70 L15,70 Q10,70 10,65 L10,43 L0,35 L10,27 L10,17';
                    pathCTM = boundingBoxCTM.translate(boundingBox.x - boundingBox.width / 2, tooltipPointLeftRightHeight + marginUpload * 3  + yOffset).scale(-1, 1); // boundingBox.y + tooltipPointLeftRightHeight
                    textCTM = boundingBoxCTM.translate(boundingBox.x - boundingBox.width - tooltipPointLeftRightWidth, marginUpload * 3  + yOffset); // boundingBox.y
                    // stringOfTooltipTextTransform = "translate(" + ( boundingBox.x - tooltipPointLeftRightWidth / 2.0 - marginUpload ) + ", " + ( boundingBox.y - tooltipPointLeftRightHeight / 2 + boundingBox.height / 2 + marginUpload * 2 ) + ")";//translate(" + ( boundingBox.x + boundingBox.width ) + ", " + ( boundingBox.y - tooltipPointLeftRightHeight / 2 ) + ")";
                    // stringOfPathTransform = "translate(" + ( boundingBox.x - marginUpload ) + ", " + ( boundingBox.y - tooltipPointLeftRightHeight / 2 + boundingBox.height / 2 ) + ")scale(-1,1)";
                }

                tooltip.attr('d', pathPoints);

                setTM(tooltip[0][0], pathCTM);

                var imageSize = { width: 18, height:18 };
                var yOffset = {upload: -8, download: 13};
                var text = detailContainer.append('text')
                    .attr('class', 'bubble_tooltip lineChart--bubble--text');

                //////////////////////////////////////////////////
                /// Upload
                var imageUpload = detailContainer.append("svg:image")
                               .attr('class', 'bubble_tooltip')
                               .attr('width', imageSize.width)
                               .attr('height', imageSize.height)
                               .attr('x', tooltipPointLeftRightWidth / 4 + marginUpload - imageSize.height / 2 )
                               .attr('y', tooltipPointLeftRightHeight / 5 * 1.25 + imageSize.height / 2 + 5 + yOffset.upload)
                               .attr("xlink:href","/images/usage_monitor/icon_upload_ss.png");

                var thisUpload = valueAndUnitAdjusted(data[parseInt(d.x)].tx, scope.unitUpload);

                text.append('tspan')
                    .attr('class', d.tx >= d.rx ? 'lineChart--bubble--dateUpload' : 'lineChart--bubble--dateDownload')
                    .attr('x', tooltipPointLeftRightWidth / 2 + marginUpload)
                    .attr('y', tooltipPointLeftRightHeight / 5 * 1.25)
                    .attr('text-anchor', 'middle')
                    .text(dateFormatValue(d.date))
                    .attr("stroke", "#000");

                var tooltipUploadValue = text.append('tspan')
                    .attr('class', 'lineChart--bubble--uploadValue' )
                    .attr('x', tooltipPointLeftRightWidth / 2 + marginUpload)
                    .attr('y', tooltipPointLeftRightHeight / 5 * 3.5 + yOffset.upload)
                    .attr('text-anchor', 'middle')
                    .text(commaFormat(thisUpload.value.toFixed(1)))
                    .attr("stroke", "#000");

                var legend = bboxOfElement(tooltipUploadValue.node()).x + bboxOfElement(tooltipUploadValue.node()).width + 5;

                if (true || legend == 5) {
                    text.append('tspan')
                        .attr('class', 'lineChart--bubble--uploadUnit')
                        .attr('x', tooltipPointLeftRightWidth - marginUpload - 35)
                        .attr('y', tooltipPointLeftRightHeight / 5 * 3.5 + yOffset.upload)
                        .attr('text-anchor', 'right')
                        .text(thisUpload.unit)
                        .attr("stroke", "#000");
                } else {
                    text.append('tspan')
                        .attr('class', 'lineChart--bubble--uploadUnit')
                        .attr('x', legend - 10)
                        .attr('y', tooltipPointLeftRightHeight / 5 * 3.5 + yOffset.upload)
                        .attr('text-anchor', 'left')
                        .text(thisUpload.unit)
                        .attr("stroke", "#000");
                }

                //////////////////////////////////////////////////
                /// Download
                var imageDownload = detailContainer.append("svg:image")
                               .attr('class', 'bubble_tooltip')
                               .attr('width', imageSize.width)
                               .attr('height', imageSize.height)
                               .attr('x', tooltipPointLeftRightWidth / 4 + marginUpload - imageSize.height / 2 )
                               .attr('y', tooltipPointLeftRightHeight / 5 * 1.25 + imageSize.height / 2 + 5 + yOffset.download)
                               .attr("xlink:href","/images/usage_monitor/icon_download_ss.png");

                var thisDownload = valueAndUnitAdjusted(data[parseInt(d.x)].rx, scope.unitDownload);

                var tooltipDownloadValue = text.append('tspan')
                    .attr('class', 'lineChart--bubble--downloadValue' )
                    .attr('x', tooltipPointLeftRightWidth / 2 + marginUpload)
                    .attr('y', tooltipPointLeftRightHeight / 5 * 3.5 + yOffset.download)
                    .attr('text-anchor', 'middle')
                    .text(commaFormat(thisDownload.value.toFixed(1)))
                    .attr("stroke", "#000");

                var legend = bboxOfElement(tooltipDownloadValue.node()).x + bboxOfElement(tooltipDownloadValue.node()).width + 5;

                if (true || legend == 5) {
                    text.append('tspan')
                        .attr('class', 'lineChart--bubble--downloadUnit')
                        .attr('x', tooltipPointLeftRightWidth - marginUpload - 35)
                        .attr('y', tooltipPointLeftRightHeight / 5 * 3.5 + yOffset.download)
                        .attr('text-anchor', 'right')
                        .text(thisDownload.unit)
                        .attr("stroke", "#000");
                } else {
                    text.append('tspan')
                        .attr('class', 'lineChart--bubble--downloadUnit')
                        .attr('x', legend - 10)
                        .attr('y', tooltipPointLeftRightHeight / 5 * 3.5 + yOffset.download)
                        .attr('text-anchor', 'left')
                        .text(thisDownload.unit)
                        .attr("stroke", "#000");
                }

                setTM(text[0][0], textCTM);
                setTM(imageUpload[0][0], textCTM);
                setTM(imageDownload[0][0], textCTM);
            }

            function hideDetail() {
                d3.selectAll(".bubble_tooltip").remove();
            }

            function increaseUnit(unit) {
                switch (unit) {
                    case "TByte":
                        return "PByte";
                    case "GByte":
                        return "TByte";
                    case "MByte":
                        return "GByte";
                    case "KByte":
                        return "MByte";
                    case "Byte":
                        return "KByte";
                }
                return "Byte";
            }

            function decreaseUnit(unit) {
                switch (unit) {
                    case "PByte":
                        return "TByte";
                    case "TByte":
                        return "GByte";
                    case "GByte":
                        return "MByte";
                    case "MByte":
                        return "KByte";
                    case "KByte":
                        return "Byte";
                }
                return "Byte";
            }

            function divisorFromUnit(unit) {
                switch (unit) {
                    case "PByte":
                        return 1000 * 1000 * 1000 * 1000 * 1000;
                    case "TByte":
                        return 1000 * 1000 * 1000 * 1000;
                    case "GByte":
                        return 1000 * 1000 * 1000;
                    case "MByte":
                        return 1000 * 1000;
                    case "KByte":
                        return 1000;
                }
                return 1;
            }

            function valueAndUnitAdjusted(value, originalUnit) {
                var returnData = {
                    value: value,
                    unit: originalUnit
                };
                if (value == 0 || value >= 1 && value < 1000) {
                    return returnData;
                } else if (value >= 1000) {
                    var unit = originalUnit;
                    do {
                        value /= 1000;
                        unit = increaseUnit(unit);
                    } while (value > 1000);
                    return {
                        value: value,
                        unit: unit
                    };
                } else {
                    var unit = originalUnit;
                    do {
                        value *= 1000;
                        unit = decreaseUnit(unit);
                    } while (value < 1);
                    return {
                        value: value,
                        unit: unit
                    };
                }
            } // valueAndUnitAdjusted

            function bboxOfElement(node) {
              var result = {x: 0, y: 0 , height:0, width:0};
              do {
                try {
                 var bbox = node.getBBox();
                 if (bbox.x == 0 && bbox.y == 0 && bbox.height == 0 && bbox.width == 0) {
                     bbox = node.getBoundingClientRect();
                     result = {x:bbox.left, y:bbox.top , height:bbox.height, width:bbox.width};
                 }
                 else {
                     result = {x:bbox.x, y:bbox.y , height:bbox.height, width:bbox.width};
                 }
                }
                catch(e) {
                }
              } while (0);

              return result;
            } // function bboxOfElement(element) {

            function setTM(element, m) {
                return element.transform.baseVal.initialize(element.ownerSVGElement.createSVGTransformFromMatrix(m));
            };

            function fitTextToSize(element, fitToWidth) {
              var bbox = bboxOfElement(element.node());

              if (bbox.width < fitToWidth) {
                return;
              }

              var fontSize = parseInt(element.style("font-size").replace("px", ""));

              while (fontSize > 1 && bbox.width > fitToWidth) {
                --fontSize;
                element.style("font-size", fontSize + "px");
                bbox = bboxOfElement(element.node());
              }

              console.log("Adjust fontsize to " + fontSize);
            }

            detailContainer = focusUpload.append( 'g' );

          }; // scope.render = function(data){


          scope.closeAndDisable = function (callback) {
            if (scope.enabled == false) {
              callback();
              return;
            }

            scope.enabled = false;

            var numTransitions = 0;

            var duration = 200;

            if (scope.data == null || scope.data.length == 0) {

            }
            else if (scope.data.length > 60) {
              duration = 20;
            }
            else if (scope.data.length > 20) {
              duration = 150;
            }

            var allCircles = svg.selectAll("rect");

            if (allCircles.size() == 0) {
              closeSVG(callback);
            }
            else {
              allCircles.transition()
                    .each( "start", function() {
                      numTransitions++;
                    })
                    .duration(1000)
                    .attr("y", 0)
                    .attr("height", 0)
                    .each( "end", function() {
                        if( --numTransitions === 0 ) {
                            closeSVG(callback);
                        }
                    });
            }

            function closeSVG(callback) {

              if (scope.enabled == true) {
                callback();
                return;
              }

              svg.selectAll("*").remove();
              svg.attr("height", 0);
              callback();

            } // function closeSVG() {

          }; // scope.closeAndDisable = function () {

          scope.openAndEnable = function () {

            if (scope.enabled == true) {
              // console.log("already enabled");
              return;
            }

            // console.log("opening chart");
            scope.enabled = true;
            scope.render(scope.data);

          }; // scope.openAndEnable = function () {


          function WaterDrop(svg) {

              //////////////////////////////////////////////////
              // Add WaterDrop
              var waterDropPath = "M132.2,47.6c-10.7-16.3-12.8-19.7-17.8-26.6c-6.7-9.2-12.7-16.4-16.8-21 c-0.6,0.7-1.2,1.5-1.8,2.2C84.5,15.8,75.5,28,68.8,37.4c-16.3,23-26.5,41.1-38.4,62.2c-6,10.6-10,18.1-14.2,27.4 c-6.8,15-10.6,23.3-12.6,35.4c-1.3,7.5-3.6,22.1,1.6,39.4c5,16.7,14.2,27.2,17.8,31.2c24.8,27.6,61,30.3,71.2,30.6 c8.8,0.3,50.1,1.6,78-30c17.9-20.2,20.8-43.2,21.4-49.6c2.5-26-8.9-47.2-25-77.6c-4.1-7.8-11.1-20-19.2-32.8 C144.8,66.2,145.2,67.4,132.2,47.6z";

              var clipPathWaterDrop = svg.append("defs").append("clipPath")
                                          .attr("id", "clipWaterDrop")
                                      .append("path")
                                          .attr("d", waterDropPath);

              var marginWaterDrop = {top:10, left:10};

              var anchorPoints = [
                  {x1: 84.3, y1: 16.5, x2: 110.3, y2: 16.5, cpOffset: 3},
                  {x1: 70.5, y1: 35.1, x2: 123.9, y2: 35.1, cpOffset: 4},
                  {x1: 57.5, y1: 54.1, x2: 136.4, y2: 54.1, cpOffset: 7},
                  {x1: 44.6, y1: 74.8, x2: 149.4, y2: 74.8, cpOffset: 11},
                  {x1: 34.8, y1: 91.8, x2: 161.3, y2: 91.8, cpOffset: 15},
                  {x1: 23, y1: 113, x2: 172, y2: 113, cpOffset: 15},
                  {x1: 13.2, y1: 133.6, x2: 182.7, y2: 133.6, cpOffset: 15},
                  {x1: 6.8, y1: 149.5, x2: 189.3, y2: 149.5, cpOffset: 15},
                  {x1: 3.1, y1: 165.7, x2: 193.8, y2: 165.7, cpOffset: 15},
                  {x1: 2, y1: 189, x2: 192.3, y2: 189, cpOffset: 15},
                  {x1: 10.2, y1: 214.4, x2: 184.1, y2: 214.4, cpOffset: 15},
                  {x1: 25.9, y1: 236.1, x2: 169.8, y2: 236.1, cpOffset: 15},
                  {x1: 39, y1: 246.7, x2: 156.3, y2: 246.7, cpOffset: 8},
                  {x1: 62.3, y1: 258, x2: 135, y2: 258, cpOffset: 3},
              ];

              var waterDrop = null;

              this.waterDrop = function() {
                  if (!waterDrop) {
                      return null;
                  }

                  return waterDrop;
              }

              this.appendToElement = function(element) {
                  if (!element || waterDrop) {
                      return;
                  }

                  waterDrop = svg.append("g")
                      .attr("class", "waterDrop")
                      .attr("transform", "translate(" + marginWaterDrop.left + "," + marginWaterDrop.top + ")scale(1)");

          	  } // this.appendToElement=function(element)

              this.transform = function(transform, showAnimation) {
                  if (!transform || !waterDrop) {
                      return;
                  }

                  if (showAnimation) {
                      waterDrop.transition()
                        .attr("transform", transform);
                  }
                  else {
                      waterDrop.attr("transform", transform);
                  }

          	  } // this.appendToElement=function(element)

              this.fillToIndex = function(fillToIndex) {
                  var returnY = 0;
                  if (!waterDrop || fillToIndex < 0 || fillToIndex > 13) {
                      return returnY;
                  }

                  waterDrop.selectAll(".waterDropClass").remove();

                  do {
                      var classOfWaterDropFill = (fillToIndex >= 10 ? "waterDropFillWarning" : "waterDropFillNormal");

                      var rectOfWater = waterDrop.append("rect")
                          .attr("x", 0)
                          .attr("y", 0)
                          .attr("width", 200)
                          .attr("height", 300)
                          .style('clip-path', 'url(#clipWaterDrop)')
                          .attr("class", classOfWaterDropFill + " waterDropClass");

                      if (fillToIndex == 0) {
                          break;
                      }
                      --fillToIndex;

                      var point0 = anchorPoints[0];
                      var duration = 1500;
                      var point = anchorPoints[fillToIndex];
                      returnY = point.y1;
                      if (fillToIndex >= 12) {
                          returnY = anchorPoints[11].y1;
                      }
                      var controlPointTop = {
                          x1: point.x1 + (point.x2 - point.x1) * 0.2,
                          y1: point.y1 - point.cpOffset,
                          x2: point.x1 + (point.x2 - point.x1) * 0.8,
                          y2: point.y1 - point.cpOffset,
                      }
                      var controlPointBottom = {
                          x1: point.x1 + (point.x2 - point.x1) * 0.2,
                          y1: point.y1 + point.cpOffset,
                          x2: point.x1 + (point.x2 - point.x1) * 0.8,
                          y2: point.y1 + point.cpOffset,
                      }

                      rectOfWater.transition()
                          .duration(duration)
                          .attr("x", 0)
                          .attr("y", point.y1)
                          .attr("width", 200)
                          .attr("height", 300)
                          .attr("class", classOfWaterDropFill + " waterDropClass");

                      waterDrop.append("path")
                          .attr("d", "M " + point.x1 + " " + point.y1 + " C " + controlPointTop.x1 + " " + controlPointTop.y1 + " " + controlPointTop.x2 + " " + controlPointTop.y2 + " " + point.x2 + " " + point.y2
                                                                      + " C " + controlPointBottom.x2 + " " + controlPointBottom.y2 + " " + controlPointBottom.x1 + " " + controlPointBottom.y1 + " " + point.x1 + " " + point.y1)
                          .attr("class", classOfWaterDropFill + " waterDropClass")
                          .style('opacity', '0.0')
                          .transition()
                              .delay(duration * 0.5)
                              .duration(duration * 0.5)
                              .style('opacity', '1.0');
                  } while (0); // do

                  waterDrop.append("path")
                      .attr("d", waterDropPath)
                      .attr("class", "waterDropOutlinePath waterDropClass");

                  return returnY;
              } // this.fillToIndex

          } // function WaterDrop



        } // link: function(scope, iElement, iAttrs)
      }; // .directive('d3Datausagealert', ['d3', function(d3) {
    }]); // angular.module('ZyXEL.directives')

}());
