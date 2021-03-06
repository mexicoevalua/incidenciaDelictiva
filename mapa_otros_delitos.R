# Véase incidencia_delictiva.R para la definición de otros delitos ya que es diferente de la del
# Secretariado Ejectutivo de Seguridad Pública
# Basado en: http://rmaps.github.io/blog/posts/animated-choropleths/index.html y
# http://bl.ocks.org/diegovalle/8967565

# Esta parte del script produce un mapa interactivo .html
# Requiere un servidor local, en la terminal de Mac usar: python -m SimpleHTTPServer 8888
#====

# Separar Otros Delitos en intervalos
dat <- transform(otros,
                 fillKey = cut(rate, breaks=c(quantile(rate, probs = seq(0, 1, by = 0.20))), dig.lab = 4, include.lowest=T, right=F)
)
table(dat$fillKey)
l  <-  c("[13 - 480)","[480 - 651)","[651 - 849)","[849 - 1,173)","[1,173 - 3,731]")
# Quitar decimales y arreglar leyenda
dat <- transform(otros,
                 fillKey = cut(rate,labels=l, breaks=c(quantile(rate, probs = seq(0, 1, by = 0.20))), dig.lab = 4, include.lowest=T, right=F)
)
keyNames <- levels(dat$fillKey)

# Colores

fills = setNames(
  c(RColorBrewer::brewer.pal(5, 'YlOrRd'), '#BD0026'),
  c(levels(dat$fillKey), 'defaultFill')
)
str(fills)

dat2 <- plyr::dlply(na.omit(dat), "year", function(x){
  y = rCharts::toJSONArray2(x, json = F)
  names(y) = lapply(y, '[[', 'name')
  return(y)
})
dat2[[1]]

# Existe un bug en la función ichoropleth de rMaps, utilizar el formato propuesto por Diego Valle-Jones 

d1 <- Datamaps$new()
d1$set(
  geographyConfig = list(
    dataUrl = "shapefiles/mx_states.json",
    popupTemplate =  "#! function(geography, data) { //this function should just return a string
    return '<div class=hoverinfo>' + geography.properties.name + ': ' + data.rate + '</div>';
    }  !#"
  ),
  dom = 'chart_1',
  scope = 'states',
  labels = TRUE,
  bodyattrs = "ng-app ng-controller='rChartsCtrl'",
  setProjection = '#! function( element, options ) {
  
  var projection, path;
  
  projection = d3.geo.mercator()
  .center([-90, 24])
  .scale(element.offsetWidth)
  .translate([element.offsetWidth / 2, element.offsetHeight / 2]);
  
  path = d3.geo.path()
  .projection( projection );
  
  return {path: path, projection: projection};
  } !#',
  fills = fills,
  data = dat2[[1]],
  legend = TRUE,
  labels = TRUE
)
d1$save("otros_delitos.html", cdn = TRUE)

#####
#### Map with slider with slider
#####
d1$addAssets(
  jshead = "http://cdnjs.cloudflare.com/ajax/libs/angular.js/1.2.1/angular.min.js"
)
d1$setTemplate(chartDiv = "
  <div id = 'chart_1' class = 'rChart datamaps'>
  <input id='slider' type='range' min=1997 max=2014 ng-model='year' width=200>
  <span ng-bind='year'></span>
    
  <script>
    function rChartsCtrl($scope){
      $scope.year = '2014';
      $scope.$watch('year', function(newYear){
        mapchart_1.updateChoropleth(chartParams.newData[newYear]);
      })
    }
  </script>
  </div>   "
)
d1$set(newData = dat2)
d1$save("otros_delitos.html", cdn = TRUE)
