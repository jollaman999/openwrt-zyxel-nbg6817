(function () {
  'use strict';

  angular.module('ZyXEL.directives')
    .directive('d3Stackedbars', ['d3', function(d3) {
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

            var detailWidth  = 98,
                detailHeight = 55,
                detailMargin = 10;

            // var n = 2, // number of layers
            //     m = 30, // number of samples per layer
            //     stack = d3.layout.stack(),
            //     layers = stack(d3.range(n).map(function() { console.log("bumpLayer(m, .1) :" + bumpLayer(m, .1)); return bumpLayer(m, .1); })),
            var n = data.length, // number of layers
                m = data[0].length, // number of samples per layer
                stack = d3.layout.stack(),
                layers = data,
                yGroupMax = d3.max(layers, function(layer) { return d3.max(layer, function(d) { return d.y; }); }),
                yStackMax = d3.max(layers, function(layer) { return d3.max(layer, function(d) { return d.y0 + d.y; }); });

            var margin = {top: 10, right: 10, bottom: 20, left: 10},

                width = d3.select(iElement[0])[0][0].offsetWidth - 20,
                  // 20 is for margins and can be changed
                height = scope.data.length * 50 + detailHeight + detailMargin;
                  // 35 = 30(bar height) + 5(margin between bars)            

            var dataDescriptionWidth = 94,
                dataDescriptionHeight = height,
                yAxisDescriptionWidth = 55;

            if (width < 20) {
              // console.log("width: " + width + ", ignore.");
              // console.log("body: " + $('body').width());
              width = $('body').width();   
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

            // adjust totalDataDescription by width
            
            if (width < 640) {
              dataDescriptionWidth = width;
              dataDescriptionHeight = 55;
              height += dataDescriptionHeight;
              svg.attr("height", height);
            }

            svg.append("rect")
              .attr("class", "boundingRect")
              .attr("width", "100%")
              .attr("height", "100%")
              .style("opacity", 0.0);            

            var totalDataDescription = svg.append("rect")
                                          .attr("class", "totalDataDescription")
                                          .attr("width",  dataDescriptionWidth)
                                          .attr("height", dataDescriptionHeight)
                                          .attr("fill", "#34c691");

            // totalDataDescription.attr("width", 94);

            // console.log("drawing stacked bar");

            var x = d3.scale.ordinal()
                .domain(d3.range(m))
                .rangeRoundBands([(dataDescriptionWidth == width ? yAxisDescriptionWidth : dataDescriptionWidth + yAxisDescriptionWidth), width * 0.97], .08);

            var y = d3.scale.linear()
                .domain([0, yStackMax])
                .range([height - detailHeight - (dataDescriptionHeight == height ? 0 : dataDescriptionHeight), 0]);

            var color = ["#56d587", "#a7eb67", "#f9f9f9"];

            var yFormatValue = d3.format(".0f");
            var dateFormatValue = d3.time.format("%m/%d");

            var xAxisTickInterval = 1;


            // adjust xAxisTickInterval by number of data and width
            if (width < 313) {
                xAxisTickInterval = Math.ceil(data[0].length -1);
            }            
            else if (data[0].length > 7) {
              if (width >= 538) {
                xAxisTickInterval = Math.ceil(data[0].length / 10);
              }
              else if (width >= 313) {
                xAxisTickInterval = Math.ceil(data[0].length / 5);
              }
            }

            // console.log("width: " + width + ", xAxisTickInterval: " + xAxisTickInterval);

            var xAxis = d3.svg.axis()
                .scale(x)
                // .ticks(10)
                .tickSize(0)
                .tickPadding(6)
                .orient("bottom")
                .tickFormat(function(d){ return ((d % xAxisTickInterval == 0 && d + xAxisTickInterval / 2 < data[0].length - 1 ) || d == data[0].length - 1 ? dateFormatValue(data[0][d].date) : '') ;});

            var yAxis = d3.svg.axis()
                .scale(y)
                // .ticks(10)
                .tickSize(0)
                .tickPadding(6)
                .orient("left")
                .tickFormat(function(d, i){ return (i % 3 == 0 ? yFormatValue(d) : '') ;});

            // console.log("calculated width, height: " + width + ", " + height );
            // console.log("svg width, height: " + svg.attr("width") + ", " + svg.attr("height") );
            // console.log(d3.select(iElement[0])[0][0]);
            // console.log(d3.select(iElement[0])[0]);
            // console.log(d3.select(iElement[0]));
            //    .append("g")
            //    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

            var layer = svg.selectAll(".layer")
                .data(layers)
              .enter().append("g")
                .attr("class", "layer")
                .style("fill", function(d, i) { return color[i]; });

            var rect = layer.selectAll("rect")
                .data(function(d) { return d; })
              .enter().append("rect")
                .attr("x", function(d) { return x(d.x); })
                .attr("y", height)
                .attr("class", "stacks")
                .attr("transform", "translate(" + offsetToCenterStack(x.rangeBand()) + "," + (detailHeight / 2 + (dataDescriptionHeight == height ? 0 : dataDescriptionHeight) ) + ")")    
                .attr("width", maxStackWidth(x.rangeBand()))
                .attr("height", 0)
                .on( 'mouseenter', function( d ) {
                    d3.select( this )
                      // .attr(
                      //   'class',
                      //   'lineChart--circle lineChart--circle__highlighted' 
                      // )
                      .attr( 'r', 7 );
                    
                      d.active = true;
                      
                      showDetail( d, this );
                  } )
                  .on( 'mouseout', function( d ) {
                    d3.select( this )
                      // .attr(
                      //   'class',
                      //   'lineChart--circle' 
                      // )
                      .attr( 'r', 6 );
                    
                    if ( d.active ) {
                      hideDetail();                      
                      d.active = false;
                    }
                  } )
                  .on('click', function( d ) {                  
                    if ( d.active ) {
                      showDetail( d, this )
                    } else {
                      hideDetail();
                    }
                  } );

            rect.transition()
                .delay(function(d, i) { return i * 10; })
                .attr("y", function(d) { return y(d.y0 + d.y); })
                .attr("height", function(d) { return y(d.y0) - y(d.y0 + d.y); });

            svg.append("g")
                .attr("class", "x axis")
                .attr("transform", "translate(0," + (height - 20) + ")")                
                .call(xAxis);

            svg.append("g")
                .attr("class", "y axis")
                .attr("transform", "translate(" + (( dataDescriptionWidth == width ? 0 : dataDescriptionWidth ) + yAxisDescriptionWidth + 10) + "," + ( detailHeight / 2 + (dataDescriptionHeight == height ? 0 : dataDescriptionHeight) ) +")")                                
                .call(yAxis);

            svg.append("text")
                    .attr("transform", "rotate(-90)")
                    .attr("y", ( dataDescriptionWidth == width ? 0 : dataDescriptionWidth ) + 5)
                    .attr("x",0 - ((height + (dataDescriptionHeight == height ? 0 : dataDescriptionHeight)) / 2))
                    .attr("dy", "1em")
                    .style("text-anchor", "middle")
                    .text(scope.translation.Data + " (" + scope.unit + ")");    

            ///////////////////////////////////////////////
            // Legends
            ///////////////////////////////////////////////

            svg.append("rect")
               .attr("width", "10")
               .attr("height", "10")
               .attr("x", x(0) + offsetToCenterStack(x.rangeBand()) )
               .attr("y", (dataDescriptionHeight == height ? 0 : dataDescriptionHeight) + margin.top )
               .attr("fill", color[1]);

            svg.append("text")
               .attr("x", x(0) + offsetToCenterStack(x.rangeBand()) + 15 )
               .attr("y", (dataDescriptionHeight == height ? 0 : dataDescriptionHeight) + margin.top + 9 )
               .style("text-anchor", "left")
               .text(scope.translation.Upload); 

            svg.append("rect")
               .attr("width", "10")
               .attr("height", "10")
               .attr("x", x(0) + offsetToCenterStack(x.rangeBand()) + 70 )
               .attr("y", (dataDescriptionHeight == height ? 0 : dataDescriptionHeight) + margin.top )
               .attr("fill", color[0]);

            svg.append("text")
               .attr("x", x(0) + offsetToCenterStack(x.rangeBand()) + 70 + 15 )
               .attr("y", (dataDescriptionHeight == height ? 0 : dataDescriptionHeight) + margin.top + 9 )
               .style("text-anchor", "left")
               .text(scope.translation.Download); 

            ///////////////////////////////////////////////
            // Descriptions
            ///////////////////////////////////////////////
            var imageSize = {width: 52, height:52};

            var iconPos     = { x: (dataDescriptionWidth) / 2 - imageSize.width / 2 , y: 2 };
            var typeDescPos = { x: (dataDescriptionWidth) / 2 , y: imageSize.height + iconPos.y + 15 };

            var uploadTitlePos = { x: (dataDescriptionWidth) / 2 , y: typeDescPos.y + 27 };
            var uploadValuePos = { x: (dataDescriptionWidth) / 2 , y: uploadTitlePos.y + 27 };
            var uploadUnitPos = { x: (dataDescriptionWidth) / 2 , y: uploadValuePos.y + 17 };

            var decrmationLinePos = { x: 5 , y: uploadValuePos.y + 25 };

            var downloadTitlePos = { x: (dataDescriptionWidth) / 2 , y: decrmationLinePos.y + 17 };
            var downloadValuePos = { x: (dataDescriptionWidth) / 2 , y: downloadTitlePos.y + 27 };
            var downloadUnitPos = { x: (dataDescriptionWidth) / 2 , y: downloadValuePos.y + 17 };

            if (dataDescriptionWidth == width) {
              imageSize = {width: 32, height:32};
              iconPos     = { x: imageSize.width / 2, y: 2 };
              typeDescPos = { x: 32 , y: imageSize.height + iconPos.y + 15  };

              uploadTitlePos = { x: dataDescriptionWidth / 4 , y: dataDescriptionHeight / 2 };
              uploadValuePos = { x: uploadTitlePos.x + 50 , y: dataDescriptionHeight / 3 + 5 };
              uploadUnitPos = { x: uploadTitlePos.x + 50 , y: dataDescriptionHeight / 3 * 2 + 5 };

              decrmationLinePos = null;

              downloadTitlePos = { x: dataDescriptionWidth / 4 * 2.5 , y: dataDescriptionHeight / 2 };
              downloadValuePos = { x: downloadTitlePos.x + 60 , y: dataDescriptionHeight / 3 + 5 };
              downloadUnitPos = { x: downloadTitlePos.x + 60 , y: dataDescriptionHeight / 3 * 2 + 5 };


            }

            svg.append("svg:image")
               .attr('width', imageSize.width)
               .attr('height', imageSize.height)
               .attr('x', iconPos.x )
               .attr('y', iconPos.y)
               .attr("xlink:href","/images/usage_monitor/icon_data.png")

            svg.append("text")
               .attr( 'class', 'totalDescription-type' )
               .attr("x", typeDescPos.x )
               .attr("y", typeDescPos.y )
               .style("text-anchor", "middle")
               .text(scope.translation.Data);    

            svg.append("text")
               .attr( 'class', 'totalDescription-title' )
               .attr("x", uploadTitlePos.x )
               .attr("y", uploadTitlePos.y )
               .style("text-anchor", "middle")
               .text(scope.translation.Upload);                                          

            svg.append("text")
               .attr( 'class', 'totalDescription-value' )
               .attr("x", uploadValuePos.x )
               .attr("y", uploadValuePos.y )
               .style("text-anchor", "middle")
               .text(scope.totalTransfer.upload);  

            svg.append("text")
               .attr( 'class', 'totalDescription-unit' )
               .attr("x", uploadUnitPos.x )
               .attr("y", uploadUnitPos.y )
               .style("text-anchor", "middle")
               .text(scope.unit); 

            if (decrmationLinePos != null) {
              svg.append("rect")
                  .attr("fill", "#2ca97c")
                  // .attr("stroke", "#2ca97c")
                  .attr("width", dataDescriptionWidth - 10)
                  .attr("height", 1)
                  .attr("x", decrmationLinePos.x)
                  .attr("y", decrmationLinePos.y);
            }

            svg.append("text")
               .attr( 'class', 'totalDescription-title' )
               .attr("x", downloadTitlePos.x )
               .attr("y", downloadTitlePos.y )
               .style("text-anchor", "middle")
               .text(scope.translation.Download);                                          

            svg.append("text")
               .attr( 'class', 'totalDescription-value' )
               .attr("x", downloadValuePos.x )
               .attr("y", downloadValuePos.y )
               .style("text-anchor", "middle")
               .text(scope.totalTransfer.download);  

            svg.append("text")
               .attr( 'class', 'totalDescription-unit' )
               .attr("x", downloadUnitPos.x )
               .attr("y", downloadUnitPos.y )
               .style("text-anchor", "middle")
               .text(scope.unit);                

            // d3.selectAll(".tick").selectAll("text").attr("fill", "#F00");

            d3.selectAll("input").on("change", change);

            var timeout = setTimeout(function() {
              d3.select("input[value=\"grouped\"]").property("checked", true).each(change);
            }, 2000);

            function change() {
              clearTimeout(timeout);
              if (this.value === "grouped") transitionGrouped();
              else transitionStacked();
            }

            function transitionGrouped() {
              y.domain([0, yGroupMax]);

              rect.transition()
                  .duration(500)
                  .delay(function(d, i) { return i * 10; })
                  .attr("x", function(d, i, j) { return x(d.x) + x.rangeBand() / n * j; })
                  .attr("width", maxStackWidth(x.rangeBand() / n))
                .transition()
                  .attr("y", function(d) { return y(d.y); })
                  .attr("height", function(d) { return height - y(d.y); });
            }

            function transitionStacked() {
              y.domain([0, yStackMax]);

              rect.transition()
                  .duration(500)
                  .delay(function(d, i) { return i * 10; })
                  .attr("y", function(d) { return y(d.y0 + d.y); })
                  .attr("height", function(d) { return y(d.y0) - y(d.y0 + d.y); })
                .transition()
                  .attr("x", function(d) { return x(d.x); })
                  .attr("width", maxStackWidth(x.rangeBand()));
            }


            function hideDetail() {
              detailContainer.selectAll(".bubble_tooltip").remove();
            }
            
            function stringFormatOfDate(date) {
                var nDay    = date.getDate();
                var nMonth  = date.getMonth()+1; //January is 0!
                var nYear   = date.getFullYear();
                return  nYear + '/' + nMonth + '/' + nDay;
            }

            function setTM(element, m) {
                return element.transform.baseVal.initialize(element.ownerSVGElement.createSVGTransformFromMatrix(m));
            };

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

            function showDetail( d, element ) {

              if (scope.enabled == false) {
                return;
              }

              // console.log("showDetail, d: ");
              // console.log(d);
              // console.log("showDetail, element: ");
              // console.log(element);


              detailContainer.selectAll(".bubble_tooltip").remove();

              var boundingBox = {x: x(d.x) + offsetToCenterStack(x.rangeBand()), y: 50 , height:height - 50, width:maxStackWidth(x.rangeBand())};

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

               var tooltip = detailContainer.append( 'path' )
                          .attr("class", "bubble_tooltipPath bubble_tooltip")
                          // .attr('d', 'M0,40 L0,5 Q0,0 5,0 L150,0 Q155,0 155,5 L155,65 Q155,70 150,70 L85,70 L77,80 L69,70 L5,70 Q0,70 0,65 L0,40')
                          // .attr("transform", "scale(1.0)translate(" + ( boundingBox.x + boundingBox.width ) + ", " + ( boundingBox.y + boundingBox.height ) + ")")
                          // .attr("transform", "scale(1.0)translate(" + ( boundingBox.x - boundingBox.width / 2 ) + ", " + ( 0 ) + ")")
                          ;              

                var svgBoundingBox = bboxOfElement(d3.select(".boundingRect").node());

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

                var margin = 5;

                var pathPoints = 'M0,40 L0,5 Q0,0 5,0 L150,0 Q155,0 155,5 L155,65 Q155,70 150,70 L85,70 L77,80 L69,70 L5,70 Q0,70 0,65 L0,40'; // points down
                // boundingBoxCTM = boundingBoxCTM.translate(boundingBox.x - tooltipPointUpDownWidth / 2 + boundingBox.width / 2, boundingBox.y - tooltipPointUpDownHeight - margin);

                var pathCTM = boundingBoxCTM.translate(boundingBox.x - tooltipPointUpDownWidth / 2 + boundingBox.width / 2, boundingBox.y - tooltipPointUpDownHeight - margin);
                var textCTM = boundingBoxCTM.translate(boundingBox.x - tooltipPointUpDownWidth / 2 + boundingBox.width / 2, boundingBox.y - tooltipPointUpDownHeight - margin);
                if (topAvailable > tooltipPointUpDownHeight + margin && leftAvailable > tooltipPointUpDownWidth / 2 && rightAvailable > tooltipPointUpDownWidth / 2 ) {
                  // console.log("show on top");
                }
                else if (bottomAvailable > tooltipPointUpDownHeight + margin && leftAvailable > tooltipPointUpDownWidth / 2 && rightAvailable > tooltipPointUpDownWidth / 2) {
                  // console.log("show on bottom");
                    // translate(" + ( boundingBox.x - tooltipPointUpDownWidth / 2 ) + ", " + ( boundingBox.y + boundingBox.height ) + ")"
                    // stringOfTooltipTextTransform = "translate(" + ( boundingBox.x + boundingBox.width / 2) + ", " + ( boundingBox.y + boundingBox.height + margin * 3.5 ) + ")";
                    // stringOfPathTransform = "translate(" + ( boundingBox.x - tooltipPointUpDownWidth / 2 + boundingBox.width / 2) + ", " + ( boundingBox.y + boundingBox.height + tooltipPointUpDownHeight + margin ) + ")scale(1,-1)";
                }
                else if (rightAvailable > tooltipPointLeftRightWidth + margin) {
                  // console.log("show on right");
                    pathPoints = 'M10,17 L10,5 Q10,0 15,0 L160,0 Q165,0 165,5 L165,65 Q165,70 160,70 L15,70 Q10,70 10,65 L10,43 L0,35 L10,27 L10,17';
                    pathCTM = boundingBoxCTM.translate(boundingBox.x + boundingBox.width + margin, margin * 3);
                    textCTM = boundingBoxCTM.translate(boundingBox.x + boundingBox.width, margin * 3); //tooltipPointLeftRightHeight
                    // stringOfTooltipTextTransform = "translate(" + ( boundingBox.x + boundingBox.width + tooltipPointLeftRightWidth / 2 ) + ", " + ( boundingBox.y - tooltipPointLeftRightHeight / 2 + boundingBox.height / 2 + margin * 2) + ")";
                    // stringOfPathTransform = "translate(" + ( boundingBox.x + boundingBox.width ) + ", " + ( boundingBox.y - tooltipPointLeftRightHeight / 2 + boundingBox.height / 2  ) + ")";
                }
                else if (leftAvailable > tooltipPointLeftRightWidth + margin ) {
                  // console.log("show on left");
                    pathPoints = 'M10,17 L10,5 Q10,0 15,0 L160,0 Q165,0 165,5 L165,65 Q165,70 160,70 L15,70 Q10,70 10,65 L10,43 L0,35 L10,27 L10,17';
                    pathCTM = boundingBoxCTM.translate(boundingBox.x  - boundingBox.width / 2, tooltipPointLeftRightHeight + margin * 3).scale(-1,1); // boundingBox.y + tooltipPointLeftRightHeight
                    textCTM = boundingBoxCTM.translate(boundingBox.x - boundingBox.width - tooltipPointLeftRightWidth, margin * 3 ); // boundingBox.y
                    // stringOfTooltipTextTransform = "translate(" + ( boundingBox.x - tooltipPointLeftRightWidth / 2.0 - margin ) + ", " + ( boundingBox.y - tooltipPointLeftRightHeight / 2 + boundingBox.height / 2 + margin * 2 ) + ")";//translate(" + ( boundingBox.x + boundingBox.width ) + ", " + ( boundingBox.y - tooltipPointLeftRightHeight / 2 ) + ")";                  
                    // stringOfPathTransform = "translate(" + ( boundingBox.x - margin ) + ", " + ( boundingBox.y - tooltipPointLeftRightHeight / 2 + boundingBox.height / 2 ) + ")scale(-1,1)";
                }

                // tooltip
                //     .attr("x", boundingBox.x)
                //     .attr("width", boundingBox.width)
                //     .attr("y", boundingBox.y)
                //     .attr("height", boundingBox.height);
                // setTM(tooltip[0][0], boundingBoxCTM);

                // tooltip
                //     .attr("x", svgBoundingBox.x)
                //     .attr("width", svgBoundingBox.width)
                //     .attr("y", svgBoundingBox.y)
                //     .attr("height", svgBoundingBox.height);

                tooltip.attr('d', pathPoints);
                       // .attr("transform", stringOfPathTransform);
                setTM(tooltip[0][0], pathCTM);

              var text = detailContainer.append( 'text' )
                                .attr( 'class', 'bubble_tooltip lineChart--bubble--text' );
              
              var commaFormat = d3.format(",");

              // var uploadDescription   = "Upload: " + commaFormat(data[1][parseInt(d.x)].y.toFixed(1)) + scope.unit ;
              // var downloadDescription = "Download: " + commaFormat(data[1][parseInt(d.x)].y0.toFixed(1)) + scope.unit;

              var thisUpload = valueAndUnitAdjusted(data[1][parseInt(d.x)].y, scope.unit);
              var thisDownload = valueAndUnitAdjusted(data[1][parseInt(d.x)].y0, scope.unit);

              var uploadDescription   = scope.translation.Upload   + ": " + commaFormat(thisUpload.value.toFixed(1)) + thisUpload.unit;
              var downloadDescription = scope.translation.Download + ": " + commaFormat(thisDownload.value.toFixed(1)) + thisDownload.unit;


              text.append( 'tspan' )
                  .attr( 'class', 'stackedChart--bubble--date' )
                  .attr( 'x', tooltipPointLeftRightWidth / 2 + margin )
                  .attr( 'y', tooltipPointLeftRightHeight / 5 * 1.25)
                  .attr( 'text-anchor', 'middle' )
                  .text( dateFormatValue(d.date))
                  .attr("stroke", "#000" );

              text.append( 'tspan' )
                  .attr( 'class', 'stackedChart--bubble--upload' )
                  .attr( 'x', tooltipPointLeftRightWidth / 2 + margin )
                  .attr( 'y', tooltipPointLeftRightHeight / 5 * 2.75 )
                  .attr( 'text-anchor', 'middle' )
                  .text( uploadDescription )
                  .attr("stroke", "#000" );
              
              text.append( 'tspan' )
                  .attr( 'class', 'stackedChart--bubble--download' )
                  .attr( 'x', tooltipPointLeftRightWidth / 2 + margin )
                  .attr( 'y', tooltipPointLeftRightHeight / 5 * 4 )
                  .attr( 'text-anchor', 'middle' )
                  .text( downloadDescription )
                  .style('color', '#000000');

              setTM(text[0][0], textCTM);

              // var details = detailContainer.append( 'g' )
              //                   .attr( 'class', 'lineChart--bubble' )
              //                   .attr(
              //                     'transform',
              //                     function() {
              //                       var result = 'translate(';                                    
              //                       result += x(d.x);
              //                       result += ', ';
              //                       result += 0;
              //                       result += ')';
                                    
              //                       return result;
              //                     }
              //                   );
              
              // details.append( 'path' )
              //         .attr( 'd', 'M2.99990186,0 C1.34310181,0 0,1.34216977 0,2.99898218 L0,47.6680579 C0,49.32435 1.34136094,50.6670401 3.00074875,50.6670401 L44.4095996,50.6670401 C48.9775098,54.3898926 44.4672607,50.6057129 49,54.46875 C53.4190918,50.6962891 49.0050244,54.4362793 53.501875,50.6670401 L94.9943116,50.6670401 C96.6543075,50.6670401 98,49.3248703 98,47.6680579 L98,2.99898218 C98,1.34269006 96.651936,0 95.0000981,0 L2.99990186,0 Z M2.99990186,0' )
              //         .attr( 'width', detailWidth )
              //         .attr( 'height', detailHeight )
              //         .attr( 'transform', 'scale(1.5, 1.0)translate(-10, 0)');
              
              // var commaFormat = d3.format(",");

              // var text = details.append( 'text' )
              //                   .attr( 'class', 'lineChart--bubble--text' );
              

              // var uploadDescription   = "Upload: " + commaFormat(data[1][parseInt(d.x)].y.toFixed(1)) + "MB" ;
              // var downloadDescription = "Download: " + commaFormat(data[1][parseInt(d.x)].y0.toFixed(1)) + "MB";

              // text.append( 'tspan' )
              //     .attr( 'class', 'stackedChart--bubble--upload' )
              //     .attr( 'x', detailWidth / 2 )
              //     .attr( 'y', detailHeight / 3 )
              //     .attr( 'text-anchor', 'middle' )
              //     .text( uploadDescription );
              
              // text.append( 'tspan' )
              //     .attr( 'class', 'stackedChart--bubble--download' )
              //     .attr( 'x', detailWidth / 2 )
              //     .attr( 'y', detailHeight / 4 * 3 )
              //     .attr( 'text-anchor', 'middle' )
              //     .text( downloadDescription );
            }

            // Inspired by Lee Byron's test data generator.
            function bumpLayer(n, o) {
              function bump(a) {
                var x = 1 / (.1 + Math.random()),
                    y = 2 * Math.random() - .5,
                    z = 10 / (.1 + Math.random());
                for (var i = 0; i < n; i++) {
                  var w = (i / n - y) * z;
                  a[i] += x * Math.exp(-w * w);
                }
              }

              var a = [], i;
              for (i = 0; i < n; ++i) a[i] = o + o * Math.random();
              for (i = 0; i < 5; ++i) bump(a);
              return a.map(function(d, i) { return {x: i, y: Math.max(0, d)}; });

            }

            function increaseUnit(unit) {
              switch (unit) {
                case "GB" :
                  return "TB";
                case "MB" :
                  return "GB";
                case "KB" :
                  return "MB";
                case "B" :
                  return "KB";
              }
              return unit;
            }

            function decreaseUnit(unit) {
              switch (unit) {
                case "TB" :
                  return "GB";
                case "GB" :
                  return "MB";
                case "MB" :
                  return "KB";
                case "KB" :
                  return "B";
              }
              return unit;
            }

            function valueAndUnitAdjusted(value, originalUnit) {
              var returnData = { value: value, unit: originalUnit };
              if (value == 0 || value >= 1 && value < 1000) {
                return returnData;
              }
              else if (value >= 1000) {
                  var unit = originalUnit;
                  do {
                    value /= 1000;
                    unit = increaseUnit(unit);
                  } while (value > 1000);
                  return {value: value, unit: unit};
              }
              else {
                  var unit = originalUnit;
                  do {
                    value *= 1000;
                    unit = decreaseUnit(unit);
                  } while (value < 1);
                  return {value: value, unit: unit};
              }
            }

            function maxStackWidth(originWidth) {
              var maxWidth = 24;
              if (originWidth > maxWidth) {
                return maxWidth;
              }
              return originWidth;
            }

            function offsetToCenterStack(originWidth) {
              var width = maxStackWidth(originWidth);
              if (width == originWidth) {
                return 0;
              }

              return (originWidth - width) / 2;

            }

            detailContainer = svg.append( 'g' );              
          }; // scope.render = function(data){

          scope.closeAndDisable = function (callback) {

            if (scope.enabled == false) {
              callback();
              return;
            }

            scope.enabled = false;

            var numTransitions = 0;

            var delay = 10;
            var duration = 200;

            if (scope.data[0].length > 60) {
              duration = 50;
              delay = 2;
            }
            else if (scope.data[0].length > 20) {
              duration = 150;
              delay = 7
            }

            svg.selectAll(".stacks").transition()
                  .each( "start", function() {
                    numTransitions++;
                  })
                  .duration(duration)
                  .delay(function(d, i) { return i * delay; })
                  .attr("y", 0)
                  .attr("height", 0)
                  .each( "end", function() {
                      if( --numTransitions === 0 ) {
                          closeSVG(callback);
                      }
                  });

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
              return;
            }

            scope.enabled = true;
            scope.render(scope.data);

          }; // scope.openAndEnable = function () {

        } // link: function(scope, iElement, iAttrs)
      }; // .directive('d3Stackedbars', ['d3', function(d3) {
    }]); // angular.module('ZyXEL.directives')

}());
