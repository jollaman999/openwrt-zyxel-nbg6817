(function () {
  'use strict';
  angular.module('ZyXEL.directives')
    .directive('d3Animatedlinechart', ['d3', function(d3) {
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

          var detailContainer = null;

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
            }

            var x = d3.time.scale().range([0, width]),
                x2 = d3.time.scale().range([0, width]),
                y = d3.scale.linear().range([height, 5]),
                y2 = d3.scale.linear().range([height2, 0]),
                y3 = d3.scale.linear().range([height3, 5]);


            var dateFormatValue = d3.time.format("%m/%d %H:00");
            var yFormatValue = d3.format(".1f");

            var xAxis = d3.svg.axis().scale(x).orient("bottom")
                            .tickFormat(function(d){ return dateFormatValue(d)}),
                xAxis2 = d3.svg.axis().scale(x2).orient("bottom")
                            .tickFormat(function(d){ return dateFormatValue(d)}),
                xAxis3 = d3.svg.axis().scale(x).orient("bottom")
                                .tickFormat(function(d){ return dateFormatValue(d)}),
                yAxis = d3.svg.axis().scale(y).orient("left")
                            .tickFormat(function(d){ return yFormatValue(d)}),
                yAxis3 = d3.svg.axis().scale(y3).orient("left")
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

                var focusDownload = svg.append("g")
                    .attr("class", "focus")
                    .attr("transform", "translate(" + marginDownload.left + "," + marginDownload.top + ")");

                var focusUpload = svg.append("g")
                    .attr("class", "focus")
                    .attr("transform", "translate(" + marginUpload.left + "," + marginUpload.top + ")");


                //////////////////////////////////////////////////
                /// Upload Peak & Unit conversion
                var yUploadMax = d3.max(data.map(function(d) { return d.uploadPeak; }));

                if (yUploadMax == 0) {
                  yUploadMax = 1;
                }

                var brushMaxUsingUpload = true;
                var orginalUploadMax = yUploadMax;
                var divisorUpload = 1;
                var divisorDownload = 1;

                var maxValueUnitUpload = valueAndUnitAdjusted(yUploadMax, scope.unitUpload);

                yUploadMax = maxValueUnitUpload.value;

                if (scope.unitUpload != maxValueUnitUpload.unit) {

                  scope.unitUpload = maxValueUnitUpload.unit;

                  var divisor = divisorFromUnit(scope.unitUpload);
                  divisorUpload = divisor;
                  if (divisor > 1) {
                    for (var index in data) {
                      data[index].uploadPeak /= divisor;
                    }
                  }

                }

                //////////////////////////////////////////////////
                /// Download Peak & Unit conversion
                var yDownloadMax = d3.max(data.map(function(d) { return d.downloadPeak; }));

                if (yDownloadMax == 0) {
                  yDownloadMax = 1;
                }

                if (orginalUploadMax < yDownloadMax) {
                    brushMaxUsingUpload = false;
                }

                var maxValueUnitDownload = valueAndUnitAdjusted(yDownloadMax, scope.unitDownload);

                yDownloadMax = maxValueUnitDownload.value;

                if (scope.unitDownload != maxValueUnitDownload.unit) {

                  scope.unitDownload = maxValueUnitDownload.unit;

                  var divisor = divisorFromUnit(scope.unitDownload);
                  divisorDownload = divisor;

                  if (divisor > 1) {
                    for (var index in data) {
                      data[index].downloadPeak /= divisor;
                    }
                  }
                }

                //////////////////////////////////////////////////
                /// Calculate statistics
                var statistics = statisticsFromData();

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

                x.domain([data[initialBrushIndex.begin].date, data[initialBrushIndex.end].date]);
                y.domain([0, yUploadMax]);
                x2.domain(d3.extent(data.map(function(d) { return d.date; })));
                y2.domain([0, brushMaxUsingUpload ? yUploadMax : yDownloadMax]);
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
                                    uploadPeak : 0,
                                    downloadPeak: 0
                                  };
                                } );

                //////////////////////////////////////////////////
                /// Areas
                var area = d3.svg.area()
                    .interpolate("monotone")
                    .x(function(d) { return x(d.date); })
                    .y0(height)
                    .y1(function(d) { return y(d.uploadPeak); });

                var area2 = d3.svg.area()
                    .interpolate("monotone")
                    .x(function(d) { return x2(d.date); })
                    .y0(height2)
                    .y1(function(d) { return y2(brushMaxUsingUpload? d.uploadPeak : d.uploadPeak * yDownloadMax / yUploadMax); });

                var area2Download = d3.svg.area()
                    .interpolate("monotone")
                    .x(function(d) { return x2(d.date); })
                    .y0(height2)
                    // .y1(function(d) { return y2(0); });
                    .y1(function(d) { return y2(brushMaxUsingUpload? d.downloadPeak * yUploadMax / yDownloadMax : d.downloadPeak ); });

                var area3 = d3.svg.area()
                    .interpolate("monotone")
                    .x(function(d) { return x(d.date); })
                    .y0(height3)
                    .y1(function(d) { return y3(d.downloadPeak); });

                //////////////////////////////////////////////////
                /// Add the area path
                focusUpload.append("path")
                  .datum(startData)
                  .attr( 'class', 'area lineChart--areaUpload' )
                  .style('fill', 'url(#lineChart--gradientBackgroundAreaUpload)')
                  .style('clip-path', 'url(#clip)')
                  .attr("d", area)
                  .transition()
                    .duration( DURATION )
                    .attrTween( 'd', tween( data, area ) );

                focusDownload.append("path")
                  .datum(startData)
                  .attr( 'class', 'area lineChart--areaDownload' )
                  .style('fill', 'url(#lineChart--gradientBackgroundAreaDownload)')
                  .style('clip-path', 'url(#clipD)')
                  .attr("d", area3)
                  .transition()
                    .duration( DURATION )
                    .attrTween( 'd', tween( data, area3 ) );

                //////////////////////////////////////////////////
                // Make Gradient attribute
                svg.append("linearGradient")
                    .attr("id", "lineChart--gradientBackgroundAreaUpload")
                    .attr("gradientUnits", "userSpaceOnUse")
                    .attr("x1", 0).attr("y1", 0 )
                    .attr("x2", 0).attr("y2", height )
                .selectAll("stop")
                    .data([
                        {offset: "0%", color: '#a7eb67', opacity: 0.3 },
                        {offset: "100%", color: '#a7eb67', opacity: 1.0 }
                    ])
                .enter().append("stop")
                    .attr("offset", function(d) { return d.offset; })
                    .attr("stop-color", function(d) { return d.color; })
                    .attr("stop-opacity", function(d) { return d.opacity; });

                // Make Gradient attribute
                svg.append("linearGradient")
                    .attr("id", "lineChart--gradientBackgroundAreaDownload")
                    .attr("gradientUnits", "userSpaceOnUse")
                    .attr("x1", 0).attr("y1", 0)
                    .attr("x2", 0).attr("y2", height)
                .selectAll("stop")
                    .data([
                        {offset: "0%", color: '#20b0d9', opacity: 0.3 },
                        {offset: "100%", color: '#20b0d9', opacity: 1.0 }
                    ])
                .enter().append("stop")
                    .attr("offset", function(d) { return d.offset; })
                    .attr("stop-color", function(d) { return d.color; })
                    .attr("stop-opacity", function(d) { return d.opacity; });

                //////////////////////////////////////////////////
                /// Line
                var lineUploadGen = d3.svg.line()
                  .x(function(d) {
                    return x(d.date);
                  })
                  .y(function(d) {
                    return y(d.uploadPeak);
                  })
                  .interpolate("monotone");

                var lineUpload = focusUpload.append( 'path' )
                  .datum( startData )
                  .attr( 'class', 'line lineChart--lineUpload' )
                  .style('clip-path', 'url(#clip)')
                  .attr( 'd', lineUploadGen )
                  .transition()
                  .duration( DURATION )
                  .delay( DURATION / 2 )
                  .attrTween( 'd', tween( data, lineUploadGen ) );

                  var lineDownloadGen = d3.svg.line()
                    .x(function(d) {
                      return x(d.date);
                    })
                    .y(function(d) {
                      return y3(d.downloadPeak);
                    })
                    .interpolate("monotone");

                  var lineDownload = focusDownload.append( 'path' )
                    .datum( startData )
                    .attr( 'class', 'line lineChart--lineDownload' )
                    .style('clip-path', 'url(#clipD)')
                    .attr( 'd', lineDownloadGen )
                    .transition()
                    .duration( DURATION )
                    .delay( DURATION / 2 )
                    .attrTween( 'd', tween( data, lineDownloadGen ) );

                var dateTicksUpload = focusUpload.append("g")
                  .attr("class", "x axis")
                  .attr("transform", "translate(0," + height + ")")
                  .call(xAxis)
                  .selectAll('.tick');

                removeOverlappingTicks(dateTicksUpload);

                var dateTicksDownload = focusDownload.append("g")
                  .attr("class", "x axis")
                  .attr("transform", "translate(0," + height3 + ")")
                  .call(xAxis3)
                  .selectAll('.tick');

                removeOverlappingTicks(dateTicksDownload);

                focusUpload.append("g")
                  .attr("class", "y axis")
                  .call(yAxis);

                focusDownload.append("g")
                .attr("class", "y axis")
                .call(yAxis3);

                var context = svg.append("g")
                    .attr("class", "context")
                    .attr("transform", "translate(" + marginBrush.left + "," + marginBrush.top + ")");

                context.append("path")
                    .datum(startData)
                    .attr( 'class', 'area lineChart--areaUpload' )
                    .style('fill', '#5ad687')
                    // .style('fill', 'blue')
                    // .style("opacity", 0.5)
                    .attr("d", area2)
                    .transition()
                    .duration( DURATION )
                    .attrTween( 'd', tween( data, area2 ) );

                context.append("path")
                    .datum(startData)
                    .attr( 'class', 'area lineChart--areaDownload' )
                    .style('fill', '#20b0d9')
                    // .style('fill', 'red')
                    .style("opacity", 0.5)
                    .attr("d", area2Download)
                    .transition()
                    .duration( DURATION )
                    .attrTween( 'd', tween( data, area2Download ) );

                dateTicksUpload = context.append("g")
                  .attr("class", "x axis")
                  .attr("transform", "translate(0," + height2 + ")")
                  .call(xAxis2)
                  .selectAll('.tick');

                removeOverlappingTicks(dateTicksUpload);

                context.append("g")
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

                var gDetailDownload = svg.append("g")
                    .style("display", "none");

                // append the circle at the intersection
                gDetailDownload.append("circle")
                    .attr("class", "y lineChart--circledownload__highlighted")
                    .attr("r", 6);

                //////////////////////////////////////////////////
                /// Mouseover for SVG
                svg.append("rect")
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
                                               (y(d.uploadPeak) + marginUpload.top) + ")");

                      showDetail( d, this, marginUpload.top, "upload" );

                  });

                  svg.append("rect")
                    .attr("id", "svgMouseDownload")
                    .attr("width", width)
                    .attr("height", height)
                    .style("fill", "none")
                    .style("pointer-events", "all")
                    .attr("transform", "translate(" + marginDownload.left + "," + marginDownload.top + ")")
                    .on("mouseover", function() { gDetailDownload.style("display", null); hideDetail(); })
                    .on("mouseout", function() { gDetailDownload.style("display", "none"); hideDetail(); })
                    .on("mousemove", function() {
                        var x0 = x.invert(d3.mouse(this)[0]),
                            i = bisectDate(data, x0, 1),
                            d0 = data[i - 1],
                            d1 = data[i],
                            d = x0 - d0.date > d1.date - x0 ? d1 : d0;

                        gDetailDownload.select("circle.y")
                            .attr("transform",
                                  "translate(" + (x(d.date) + marginDownload.left) + "," +
                                                 (y3(d.downloadPeak) + marginDownload.top) + ")");

                        showDetail( d, this, marginDownload.top, "download" );

                    });

                  ///////////////////////////////////////////////
                  // Y axis descriptions
                  svg.append("text")
                          .attr("transform", "rotate(-90)")
                          .attr("y", + 10)
                          .attr("x", - DETAIL_HEIGHT * 4 )
                          .attr("dy", "1em")
                          .style("text-anchor", "middle")
                          .text(scope.translation.PeakBandwidth + " (" + scope.unitUpload + ")");

                  svg.append("text")
                          .attr("transform", "rotate(-90)")
                          .attr("y", + 10)
                          .attr("x", - DETAIL_HEIGHT * 3 - marginDownload.top )
                          .attr("dy", "1em")
                          .style("text-anchor", "middle")
                          .text(scope.translation.PeakBandwidth + " (" + scope.unitUpload + ")");

                  ///////////////////////////////////////////////
                  // Legends: Upload
                  ///////////////////////////////////////////////
                  var commaFormat = d3.format(",");
                  var imageSize = { width: 40, height:36 };

                  var iconPos     = { x: 5 , y: 5 - DETAIL_HEIGHT - imageSize.height / 2 };

                  focusUpload.append("svg:image")
                     .attr('width', imageSize.width)
                     .attr('height', imageSize.height)
                     .attr('x', iconPos.x )
                     .attr('y', iconPos.y)
                     .attr("xlink:href","/images/usage_monitor/icon_upload.png");

                  var elementUploadPeakDesc = focusUpload.append("text")
                     .attr("x", 15 + imageSize.width )
                     .attr("y", 9 - DETAIL_HEIGHT )
                     .style("text-anchor", "start")
                     .text(scope.translation.UploadPeak + ":");

                  var dxlegend = bboxOfElement(elementUploadPeakDesc.node()).x + bboxOfElement(elementUploadPeakDesc.node()).width + 10;

                  var uploadValuePos = { x: dxlegend , y: 9 - DETAIL_HEIGHT };

                  var uploadPeak = valueAndUnitAdjusted(statistics.maxUploadPeak, scope.unitUpload);
                  var uploadPeakDescription   = commaFormat(uploadPeak.value.toFixed(1));

                  var uploadValueElement = focusUpload.append("text")
                     .attr( 'class', 'bandwidthDescription-uploadValue' )
                     .attr("x", uploadValuePos.x )
                     .attr("y", uploadValuePos.y )
                     .style("text-anchor", "start")
                     .text(uploadPeakDescription);

                  dxlegend = bboxOfElement(uploadValueElement.node()).x + bboxOfElement(uploadValueElement.node()).width + 10;

                  var uploadUnitPos = { x: dxlegend , y: 9 - DETAIL_HEIGHT };

                  var uploadUnitElement = focusUpload.append("text")
                     .attr( 'class', 'bandwidthDescription-uploadUnit' )
                     .attr("x", uploadUnitPos.x )
                     .attr("y", uploadUnitPos.y )
                     .style("text-anchor", "start")
                     .text(uploadPeak.unit);

                 ///////////////////////////////////////////////
                 // Legends: Download
                 ///////////////////////////////////////////////
                 var iconPos     = { x: 5 , y: 5 - DETAIL_HEIGHT - imageSize.height / 2 };

                 focusDownload.append("svg:image")
                    .attr('width', imageSize.width)
                    .attr('height', imageSize.height)
                    .attr('x', iconPos.x )
                    .attr('y', iconPos.y)
                    .attr("xlink:href","/images/usage_monitor/icon_download.png");

                 var elementDownloadPeakDesc = focusDownload.append("text")
                    .attr("x", 15 + imageSize.width )
                    .attr("y", 9 - DETAIL_HEIGHT )
                    .style("text-anchor", "start")
                    .text(scope.translation.DownloadPeak + ":");

                 var dxlegend = bboxOfElement(elementUploadPeakDesc.node()).x + bboxOfElement(elementDownloadPeakDesc.node()).width + 10;

                 var downloadValuePos = { x: dxlegend , y:  9 - DETAIL_HEIGHT };

                 // var uploadAvareage = valueAndUnitAdjusted(avearageUploadPeak, scope.unit);
                 // var uploadAverageDescription   = commaFormat(uploadAvareage.value.toFixed(1));
                 var downloadPeak = valueAndUnitAdjusted(statistics.maxDownloadPeak, scope.unitDownload);
                 var downloadPeakDescription   = commaFormat(downloadPeak.value.toFixed(1));

                 var downloadValueElement = focusDownload.append("text")
                    .attr( 'class', 'bandwidthDescription-downloadValue' )
                    .attr("x", downloadValuePos.x )
                    .attr("y", downloadValuePos.y )
                    .style("text-anchor", "start")
                    .text(downloadPeakDescription);

                 dxlegend = bboxOfElement(downloadValueElement.node()).x + bboxOfElement(downloadValueElement.node()).width + 10;

                 var downloadUnitPos = { x: dxlegend , y: 9 - DETAIL_HEIGHT };

                 var downloadUnitElement = focusDownload.append("text")
                    .attr( 'class', 'bandwidthDescription-downloadUnit' )
                    .attr("x", downloadUnitPos.x )
                    .attr("y", downloadUnitPos.y )
                    .style("text-anchor", "start")
                    .text(downloadPeak.unit);

            function changeSummarizeStatistics(statistics) {

                if (statistics == null ||
                    uploadValueElement == null || downloadValueElement == null ||
                    downloadValueElement == null || downloadUnitElement == null) {
                    return;
                }

                var uploadPeak = valueAndUnitAdjusted(statistics.maxUploadPeak, scope.unitUpload);
                var uploadPeakDescription   = commaFormat(uploadPeak.value.toFixed(1));

                uploadValueElement.text(uploadPeakDescription);

                var dxlegend = bboxOfElement(uploadValueElement.node()).x + bboxOfElement(uploadValueElement.node()).width + 10;

                var uploadUnitPos = { x: dxlegend , y: 9 - DETAIL_HEIGHT };

                uploadUnitElement.attr("x", uploadUnitPos.x )
                   .attr("y", uploadUnitPos.y )
                   .text(uploadPeak.unit);

               var downloadPeak = valueAndUnitAdjusted(statistics.maxDownloadPeak, scope.unitDownload);
               var downloadPeakDescription   = commaFormat(downloadPeak.value.toFixed(1));

               downloadValueElement.text(downloadPeakDescription);

               var dxlegend = bboxOfElement(downloadValueElement.node()).x + bboxOfElement(downloadValueElement.node()).width + 10;

               var downloadUnitPos = { x: dxlegend , y: 9 - DETAIL_HEIGHT };

               downloadUnitElement.attr("x", downloadUnitPos.x )
                  .attr("y", downloadUnitPos.y )
                  .text(downloadPeak.unit);

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
                var totalUploadPeak = 0;
                var totalDownloadPeak = 0;
                var avearageUploadPeak = 0;
                var avearageDownloadPeak = 0;
                var maxDownloadPeak = 0;
                var maxUploadPeak = 0;

                for (var index in data) {
                    if (scope.initialBrushIndex.end >= index && index >= scope.initialBrushIndex.begin) {
                        if (data[index].downloadPeak > 0 || data[index].uploadPeak > 0) {
                            ++numValidDays;
                            totalUploadPeak += data[index].uploadPeak;
                            totalDownloadPeak += data[index].downloadPeak;
                            if (maxDownloadPeak < data[index].downloadPeak) {
                                maxDownloadPeak = data[index].downloadPeak;
                            }
                            if (maxUploadPeak < data[index].uploadPeak) {
                                maxUploadPeak = data[index].uploadPeak;
                            }
                        }
                    }
                }

                if (numValidDays > 0) {
                  avearageUploadPeak = totalUploadPeak / numValidDays;
                  avearageDownloadPeak = totalDownloadPeak / numValidDays;
                }

                return {
                    numValidDays : numValidDays,
                    totalUploadPeak : totalUploadPeak,
                    totalDownloadPeak : totalDownloadPeak,
                    avearageUploadPeak : avearageUploadPeak,
                    avearageDownloadPeak : avearageDownloadPeak,
                    maxDownloadPeak : maxDownloadPeak,
                    maxUploadPeak : maxUploadPeak
                };

            }

            function brushed() {

                var currentRange = (brush.empty()? undefined : brush.extent());
                scope.initialBrushIndex = converToIndexWithCurrentRange(currentRange);
                changeSummarizeStatistics(statisticsFromData());

                x.domain(brush.empty() ? x2.domain() : brush.extent());
                focusUpload.select(".area")
                    .datum(data)
                    .attr("d", area);
                focusUpload.select(".line")
                      .datum(data)
                      .attr("d", lineUploadGen);

                focusDownload.select(".area")
                  .datum(data)
                  .attr("d", area3);
                focusDownload.select(".line")
                    .datum(data)
                    .attr("d", lineDownloadGen);

                var ticks = focusUpload.select(".x.axis").call(xAxis).selectAll('.tick');
                removeOverlappingTicks(ticks);

                ticks = focusDownload.select(".x.axis").call(xAxis).selectAll('.tick');
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


                function showDetail(d, element, yOffset, showType) {

                    if (scope.enabled == false) {
                        return;
                    }

                    if (scope.initialBrushIndex.end < d.x || d.x < scope.initialBrushIndex.begin) {
                        gDetailUpload.style("display", "none");
                        gDetailDownload.style("display", "none");
                        return;
                    }

                    if (showType == "upload") {
                        gDetailUpload.style("display", null);
                    }
                    else {
                        gDetailDownload.style("display", null);
                    }

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
                        .attr("class", (showType == "upload" ? "bubble_tooltipPathUpload" : "bubble_tooltipPathDownload") + " bubble_tooltip")
                        // .attr('d', 'M0,40 L0,5 Q0,0 5,0 L150,0 Q155,0 155,5 L155,65 Q155,70 150,70 L85,70 L77,80 L69,70 L5,70 Q0,70 0,65 L0,40')
                        // .attr("transform", "scale(1.0)translate(" + ( boundingBox.x + boundingBox.width ) + ", " + ( boundingBox.y + boundingBox.height ) + ")")
                        // .attr("transform", "scale(1.0)translate(" + ( boundingBox.x - boundingBox.width / 2 ) + ", " + ( 0 ) + ")")
                    ;

                    var svgBoundingBox = bboxOfElement(showType == "upload" ? d3.select("#svgMouseDownload").node() : d3.select("#svgMouseUpload").node());

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

                    var text = detailContainer.append('text')
                        .attr('class', 'bubble_tooltip lineChart--bubble--text');

                    var thisUpload = null;

                    if (showType == "upload") {
                        thisUpload = valueAndUnitAdjusted(data[parseInt(d.x)].uploadPeak, scope.unitUpload);
                    }
                    else {
                        thisUpload = valueAndUnitAdjusted(data[parseInt(d.x)].downloadPeak, scope.unitDownload);
                    }
                    text.append('tspan')
                        .attr('class', showType == "upload" ? 'lineChart--bubble--dateUpload' : 'lineChart--bubble--dateDownload')
                        .attr('x', tooltipPointLeftRightWidth / 2 + marginUpload)
                        .attr('y', tooltipPointLeftRightHeight / 5 * 1.25)
                        .attr('text-anchor', 'middle')
                        .text(dateFormatValue(d.date))
                        .attr("stroke", "#000");

                    var tooltipUploadValue = text.append('tspan')
                        .attr('class', showType == "upload" ? 'lineChart--bubble--uploadValue' : 'lineChart--bubble--downloadValue' )
                        .attr('x', tooltipPointLeftRightWidth / 2 + marginUpload)
                        .attr('y', tooltipPointLeftRightHeight / 5 * 3.5)
                        .attr('text-anchor', 'middle')
                        .text(commaFormat(thisUpload.value.toFixed(1)))
                        .attr("stroke", "#000");

                    var legend = bboxOfElement(tooltipUploadValue.node()).x + bboxOfElement(tooltipUploadValue.node()).width + 5;

                    if (true || legend == 5) {
                        text.append('tspan')
                            .attr('class', showType == "upload" ? 'lineChart--bubble--uploadUnit' : 'lineChart--bubble--downloadUnit')
                            .attr('x', tooltipPointLeftRightWidth - marginUpload - 35)
                            .attr('y', tooltipPointLeftRightHeight / 5 * 3.5)
                            .attr('text-anchor', 'right')
                            .text(thisUpload.unit)
                            .attr("stroke", "#000");
                    } else {
                        text.append('tspan')
                            .attr('class', showType == "upload" ? 'lineChart--bubble--uploadUnit' : 'lineChart--bubble--downloadUnit')
                            .attr('x', legend - 10)
                            .attr('y', tooltipPointLeftRightHeight / 5 * 3.5)
                            .attr('text-anchor', 'left')
                            .text(thisUpload.unit)
                            .attr("stroke", "#000");
                    }

                    setTM(text[0][0], textCTM);
                }

            function hideDetail() {
                d3.selectAll(".bubble_tooltip").remove();
            }

            function increaseUnit(unit) {
                switch (unit) {
                    case "Gbps":
                        return "Tbps";
                    case "Mbps":
                        return "Gbps";
                    case "Kbps":
                        return "Mbps";
                    case "bps":
                        return "Kbps";
                }
                return "bps";
            }

            function decreaseUnit(unit) {
                switch (unit) {
                    case "Tbps":
                        return "Gbps";
                    case "Gbps":
                        return "Mbps";
                    case "Mbps":
                        return "Kbps";
                    case "Kbps":
                        return "bps";
                }
                return "bps";
            }

            function divisorFromUnit(unit) {
                switch (unit) {
                    case "Tbps":
                        return 1000 * 1000 * 1000 * 1000;
                    case "Gbps":
                        return 1000 * 1000 * 1000;
                    case "Mbps":
                        return 1000 * 1000;
                    case "Kbps":
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
                 result = {x:bbox.x, y:bbox.y , height:bbox.height, width:bbox.width};
                }
                catch(e) {
                }
              } while (0);

              return result;
            } // function bboxOfElement(element) {

            function setTM(element, m) {
                return element.transform.baseVal.initialize(element.ownerSVGElement.createSVGTransformFromMatrix(m));
            };

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


        } // link: function(scope, iElement, iAttrs)
      }; // .directive('d3Animatedlinechart', ['d3', function(d3) {
    }]); // angular.module('ZyXEL.directives')

}());
