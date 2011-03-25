$(function() {
    $.getJSON('/data', function(data) {

      series = [
        {name : "Sensor 0", data : []},
        {name : "Sensor 1", data : []},
        {name : "Sensor 2", data : []}
      ]

      $.each(data, function(index, value) {
        // series.push([new Date(value.time).getTime(), value.fahrenheit])
        series[value.sensor].data.push([new Date(value.time).getTime(), value.fahrenheit])
      });

      console.log(series)

      chart1 = new Highcharts.Chart({
       chart: {
          renderTo: 'placeholder',
          defaultSeriesType: 'spline'
       },
       title: {
          text: 'Temp'
       },
       plotOptions: {
         spline: {
            lineWidth: 4,
            states: {
               hover: {
                  lineWidth: 5
               }
            },
            marker: {
               enabled: false,
               states: {
                  hover: {
                     enabled: true,
                     symbol: 'circle',
                     radius: 5,
                     lineWidth: 1
                  }
               }   
            }
         }
      },
      series: series,
      xAxis: {
        type: 'datetime',
        tickInterval: 3600 * 1000,
        showFirstLabel : true,
        showLastLabel: true }
    });
  });
});

