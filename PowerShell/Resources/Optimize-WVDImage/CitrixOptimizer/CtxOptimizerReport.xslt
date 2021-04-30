<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl">
  <xsl:output method="html" omit-xml-declaration="yes" indent="yes" encoding="utf-8" />
  <xsl:template match="/">
    <xsl:apply-templates />
  </xsl:template>
  <xsl:template match="root">
    <html>
      <head>
        <meta http-equiv="cache-control" content="max-age=0" />
        <meta http-equiv="cache-control" content="no-cache" />
        <meta http-equiv="expires" content="0" />
        <meta http-equiv="expires" content="Tue, 01 Jan 1980 1:00:00 GMT" />
        <meta http-equiv="pragma" content="no-cache" />
        <title>Citrix Optimizer Report</title>
        <style type="text/css">
          body {
          margin: 0 auto;
          text-align: center;
          font-family: Arial, Helvetica, sans-serif;}

          .container {
          margin: 0 auto;
          padding: 5px;
          display: inline-block;
          text-align: left;
          font-size: 12px;
          width: 1024;}

          .logo {
          float: right;}

          .hr-solid {
          clear: both;
          border-top: solid 1px #ccc;
          height: 3px;
          padding:0;
          margin: 5px 0 10px 0;}

          .hr-dash {
          border-top: dashed 1px #ccc;
          height: 3px;
          padding:0;
          margin: 10px 0;}

          table {
          border: solid 1px #ccc;
          width: 100%;}

          table.summary {
          border: 0;}

          td.right {
          text-align: right;}

          td.center {
          text-align: center;
          vertical-align: middle;}

          td.center div {
          vertical-align: middle;
          display: inline-block;
          }

          td, th {
          padding: 3px;
          text-align: left;
          vertical-align: top;}

          th.alt {
          border-right: solid 1px #ccc;}

          th.center {
          text-align: center;}

          th {
          background: #ffffff; /* Old browsers */
          background: -moz-linear-gradient(top,  #ffffff 0%, #efefef 99%, #cccccc 100%); /* FF3.6+ */
          background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#ffffff), color-stop(99%,#efefef), color-stop(100%,#cccccc)); /* Chrome,Safari4+ */
          background: -webkit-linear-gradient(top,  #ffffff 0%,#efefef 99%,#cccccc 100%); /* Chrome10+,Safari5.1+ */
          background: -o-linear-gradient(top,  #ffffff 0%,#efefef 99%,#cccccc 100%); /* Opera 11.10+ */
          background: -ms-linear-gradient(top,  #ffffff 0%,#efefef 99%,#cccccc 100%); /* IE10+ */
          background: linear-gradient(to bottom,  #ffffff 0%,#efefef 99%,#cccccc 100%); /* W3C */
          filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#ffffff', endColorstr='#cccccc',GradientType=0 ); /* IE6-9 */
          <!--padding: 10px 0 10px 5px;-->
          border-bottom: solid 1px #ccc;
          font-weight: 600;
          font-size: 12px;}

          td {
          font-size: 12px;}

          tr.alt {
          background-color: #efefef;}

          tr.entry:nth-child(odd) {
          background-color: #dddddd;}

          .footer {
          clear: both;
          border-bottom: solid 1px #ccc;
          height: 3px;
          padding: 0;
          margin: 10px 0 5px 0;}

          img.mark {
          height: 3em;
          vertical-align: middle}

          div.optimized {
          background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAnCAYAAABJ0cukAAAAAXNSR0IArs4c6QAABJVJREFUWAntmW1oHEUYx/+zm7Q12mJEChL9UESqaSyCKIq2JFUiCailsrdpbZGWkloxH3yloHeZ5AriS1QKilRBaRC9uwSFQFFrX1JB/aSgXIpQFP1iQaEGKjatt+t/7oW7ndm7XHO5yxXcD9l5/jPzzO+Z970IXC5PzH0Yvr8FdudOSOkVsFsKiaZ+S7cXGS9BxuXwZub4Hizw2oVE075lZCM8f4p8V+QZb0fPulWYnvlC2SIvNudLOncigy8Jt1IDnIONLsjUaUvLaB5Tbl2PjPjMhBcXIYSj4BVscwYQd9bC+/cI4LdrPZphz2/HaFJNqezTfIs47qzBBRwl3eo8Y+HlE343ZDJZENS7uUZgv9ORh+8ohcylrSc5bT7Q9eYJQO5Yjblsz6/RIbnVPI944m1Dp9AcAUjnGnjnOeex1oAUYgSjqVcNPS8sfQAv71oJj7uNj/UGpBBjXLDS0EuEpT0H5GAbvLMKfkMJUy5piXcwktxr6JqwdCNwYGg5Mmc/CYWHOASZeEJjDTWXJgApW/DHGbUd9oZQTeBWfxcPKz8kz5AaH4CUFjIz4yR5yKCBOIzr27chksqYeeFKYwPwfUH4d3nCDoTgHIPd9gj2HLwYkldWauxt1D91gPCPGzQCX2PVin68cOgfI28eoXEjMOy8xA+SIYNHiO/Qhn48N/63kVeF0JgAopEX4WFfCE8alv0A9qVmQ/Kqkup/DsQiT7HnXzdoBE7zHrCB95szRt4lCMURUF8+w87YJdSdv2jUGSwD/xvh76sVXgHkFnHUvYMNfc5DpRvd667k55q6l9T2yMh2fvC9Ryf6KP/OVnsI/0ttDeRq25BuF+Cp+/fVeYf3oJvSdHp6wQ1Idwsy/oesH9zlhPiTyibC/7Rg31pFGxs7J9jzN2s6R6LrHIP4RtPnN2NuH3xvggVbtcKzaLXvx3DyR02vybSwzH6UHn41vPj+a4hGzD3bKFgiyIFuwk+yQ5aVqGoSnaPdh9jH3wf0RTBy8zPu3ogL3lf0d53m02fjj/E+Pq7ppindu+B5Rwh/VSBTiPO0+3ktPh7QF8koLjDpdPJePs3FfK3mO8OLlUuASU0vmtK5jfv8ccIX1lE+j78g2NjM79jDxcKLmyrZRlMzaLF62eN/aU3YBPsIMtKv6Tkz7t7CwFXPa/D8RUdgaz3hFUAxAGWpOWpZffk5q5T847eyhycRi/QUlOw7N/WOhoyamno7K45awNHCjWAAyo9MfMvj/UGmghcr31/BXp5C1Lk729z+gRu4btT2q68bLlprb1XrJuuotj/FNaD7UdshvE8JHdxRgFnYYhv3+TdZ5Sa9Gu1nEE+ZV4eQgoshlQ9Aec8eSJ76cgoeSOVaFiLGaRMvl10PvTLYifQpbOr6mXNiMxuvHKwlXiF8tB6QlXxWDkDVPJH+gae1ujGqdRH+CPEW4Z8Oz6yvai7isPbiqYM8C8IBhXgfI4mhsGqN0KoLQJGMJt/gLApOEYEErM7d1f6CUI+A5p9Cpa2eTJ/kf0fUdnovoafQ0T6AZ8cypUUuj3TM3QP1w9T/T+098B85PTmAC2n7bwAAAABJRU5ErkJggg==');
          background-repeat: no-repeat;
          background-size: cover;
          height: 2em;
          width: 2em;}

          div.notoptimized {
          background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAAwCAYAAACrF9JNAAAAAXNSR0IArs4c6QAABXFJREFUaAXVWmtoHFUUPufu5jWbtE0tjZa2lN2kRoKo1F+KWqQiYlEqEkUURMEHom3qbpLaarZKbTdpm7agP4yCP+Iv7c+2KohWsYogWhGszSZojVgJYtvMbB6bneO5kQmz2bmTubtJk70Q7r3nfOfx7X3NzA1CicVMRPcT4MoS3QQyR8DjtT3pTwOBXSB0tbWbZjz6GAF8oG1YpAEiXIhc19CMO78Z03EhdMBuLCU3GYCYcssWuk0E682LIx26cYomaWYudRLRWt2ApeKR7ERmd2ydjp+iSI51RNejTXGdQPOF5dE07Ano1vFXFMlcDnt4LdboBJpPLAE9mknEbg/qU5vkWGLjHRykNWiAhcLZBEcpmQyUfyCQk6h0mqPcUae/mDX/0JsyVv+TQXLQIslOn2LntwRxfDUwBPab1H593VyxwnMBHD0lG5dZJu1z+lp1zXIIt2xRmkydPQGQHVfqVQrehBosmnqV9e0qjJQHJmlZ9BqP4mo/ZyqdqF8D1Y+oN0Rr4GugyxdV5v5yhO3jnbF3qg8MplXAQNN1PBFtYgcvqpwsppzP6spsDg755RCI5BTAYenMz9Gi6ogeMNub7lHlMCdJs6PxXp77W1UOloyc7F5KbvZcfr4kpRHZ1LtkiPgkwjOtxbT+eN4L4kvSsi68AEQ3eBkuSRlRkpItBa99SpK0q/kafnTrWpJk1EmtzFhjr89WK0maU5NvAEH9bIOl3uf947nRjsYWd56eJM2O6I1I8IwbWC5tnn0htO0j7nw9SUIOj0iwG1hObR7NLVa88UEn5wKSmXhsGz/Z3O0AyrW2kQ7xJjR9tueRpGONVTmEg+VKLC9vopiVGWuTsjyS1jDs5CMjmgcu4w4R7jYTLdfOkJTnCx/8r5Qxp8LUieoIxrtmSELXz//yJ79zhcjyliDimRmS3CEhYHt5U8rPngftu0hqoH+GpFQbqcEzrLhqH4vzU5rfHn81J4Fi+/TgzXbNik4mmpktL78+9hvd6W9l3nkjKQWsGEbCA7JdroVH0RJVoV1O/gUkpcJYs/ogA393QOVW88XQfmPf+T+dvD1JygsVQpFwQOVU81L7zahdl/c5hAdMXUbj0dOsvVON0NCEKtTgXFat09SEMPSw0TNw3G3mOZIOQITFDv5lbKdfUi2JqP5KcuwyRjw9m6DU+pKMHEj/QIjvudws2aYcDBQhz3Pe88NPHhMD9oAFrfwCvTxPXkQnfNNWqLjraRCrNoD9dxomP3sbcuc+L8JToQnfdvfVpc6fLdQA+K5Jx8Bsj73Mz7UlvZ1U3PY4VG3b67icqcf7X4LpL+gzkqIal2orxEbcnx7xsvadro5BJLbiGLfPO33tmudS5X3e15mV93dqu5ttwCO1V0VQYgORxGe/z4oQv4YVWbB+LWB1nae1vEKAqlpPXSAhwq+Rpvq3/LCBSEoHkdTQCT5kP/FzptLJew6amvBUk/kPwITpqQsiFALb5CD4YQOTlE4qhGjjB16+NdAsfHRkv3rf02jyiz5PeRAh53Iykho8NRdWi2RV98Av7NB3aqgCTn58eHo3pcn//zuFxk2YONkD2S/fVZn4ynlWZcMYDrSEAu2u7miUvHmFaY4O8JvMKrc8cBsF4LIGoCt8Vcef1YotvJf11vYMBSKpNZIyIUz+eEkIkhefxRWy+S7yr5II8v8PjUQEFJ5Hioy0SUo/xq2b+viX/Enhc8HFAmEPpoYuBw1UFEls/TDHj3s7ggaZTxyvr7OG8YTWQtZek+6ER+Mxftqnh9yyhW6HUWyu6Umf1olT1Eg6AcLV4Tjvct4HoAOa3/ojXYIyfEkjKR2MdTZvEDhlyPZCl8oqGMZk+opunP8AbpyniBK981EAAAAASUVORK5CYII=');
          background-repeat: no-repeat;
          background-size: contain;
          height: 2em;
          width: 2em;}

          div.success {
          display: inline-block;
          margin-right: 0.5em;
          vertical-align: middle;
          background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAnCAYAAABJ0cukAAAAAXNSR0IArs4c6QAABJVJREFUWAntmW1oHEUYx/+zm7Q12mJEChL9UESqaSyCKIq2JFUiCailsrdpbZGWkloxH3yloHeZ5AriS1QKilRBaRC9uwSFQFFrX1JB/aSgXIpQFP1iQaEGKjatt+t/7oW7ndm7XHO5yxXcD9l5/jPzzO+Z970IXC5PzH0Yvr8FdudOSOkVsFsKiaZ+S7cXGS9BxuXwZub4Hizw2oVE075lZCM8f4p8V+QZb0fPulWYnvlC2SIvNudLOncigy8Jt1IDnIONLsjUaUvLaB5Tbl2PjPjMhBcXIYSj4BVscwYQd9bC+/cI4LdrPZphz2/HaFJNqezTfIs47qzBBRwl3eo8Y+HlE343ZDJZENS7uUZgv9ORh+8ohcylrSc5bT7Q9eYJQO5Yjblsz6/RIbnVPI944m1Dp9AcAUjnGnjnOeex1oAUYgSjqVcNPS8sfQAv71oJj7uNj/UGpBBjXLDS0EuEpT0H5GAbvLMKfkMJUy5piXcwktxr6JqwdCNwYGg5Mmc/CYWHOASZeEJjDTWXJgApW/DHGbUd9oZQTeBWfxcPKz8kz5AaH4CUFjIz4yR5yKCBOIzr27chksqYeeFKYwPwfUH4d3nCDoTgHIPd9gj2HLwYkldWauxt1D91gPCPGzQCX2PVin68cOgfI28eoXEjMOy8xA+SIYNHiO/Qhn48N/63kVeF0JgAopEX4WFfCE8alv0A9qVmQ/Kqkup/DsQiT7HnXzdoBE7zHrCB95szRt4lCMURUF8+w87YJdSdv2jUGSwD/xvh76sVXgHkFnHUvYMNfc5DpRvd667k55q6l9T2yMh2fvC9Ryf6KP/OVnsI/0ttDeRq25BuF+Cp+/fVeYf3oJvSdHp6wQ1Idwsy/oesH9zlhPiTyibC/7Rg31pFGxs7J9jzN2s6R6LrHIP4RtPnN2NuH3xvggVbtcKzaLXvx3DyR02vybSwzH6UHn41vPj+a4hGzD3bKFgiyIFuwk+yQ5aVqGoSnaPdh9jH3wf0RTBy8zPu3ogL3lf0d53m02fjj/E+Pq7ppindu+B5Rwh/VSBTiPO0+3ktPh7QF8koLjDpdPJePs3FfK3mO8OLlUuASU0vmtK5jfv8ccIX1lE+j78g2NjM79jDxcKLmyrZRlMzaLF62eN/aU3YBPsIMtKv6Tkz7t7CwFXPa/D8RUdgaz3hFUAxAGWpOWpZffk5q5T847eyhycRi/QUlOw7N/WOhoyamno7K45awNHCjWAAyo9MfMvj/UGmghcr31/BXp5C1Lk729z+gRu4btT2q68bLlprb1XrJuuotj/FNaD7UdshvE8JHdxRgFnYYhv3+TdZ5Sa9Gu1nEE+ZV4eQgoshlQ9Aec8eSJ76cgoeSOVaFiLGaRMvl10PvTLYifQpbOr6mXNiMxuvHKwlXiF8tB6QlXxWDkDVPJH+gae1ujGqdRH+CPEW4Z8Oz6yvai7isPbiqYM8C8IBhXgfI4mhsGqN0KoLQJGMJt/gLApOEYEErM7d1f6CUI+A5p9Cpa2eTJ/kf0fUdnovoafQ0T6AZ8cypUUuj3TM3QP1w9T/T+098B85PTmAC2n7bwAAAABJRU5ErkJggg==');
          background-repeat: no-repeat;
          background-size: cover;
          height: 2em;
          width: 2em;}

          div.failed {
          display: inline-block;
          margin-right: 0.5em;
          vertical-align: middle;
          background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAAwCAYAAACrF9JNAAAAAXNSR0IArs4c6QAABXFJREFUaAXVWmtoHFUUPufu5jWbtE0tjZa2lN2kRoKo1F+KWqQiYlEqEkUURMEHom3qbpLaarZKbTdpm7agP4yCP+Iv7c+2KohWsYogWhGszSZojVgJYtvMbB6bneO5kQmz2bmTubtJk70Q7r3nfOfx7X3NzA1CicVMRPcT4MoS3QQyR8DjtT3pTwOBXSB0tbWbZjz6GAF8oG1YpAEiXIhc19CMO78Z03EhdMBuLCU3GYCYcssWuk0E682LIx26cYomaWYudRLRWt2ApeKR7ERmd2ydjp+iSI51RNejTXGdQPOF5dE07Ano1vFXFMlcDnt4LdboBJpPLAE9mknEbg/qU5vkWGLjHRykNWiAhcLZBEcpmQyUfyCQk6h0mqPcUae/mDX/0JsyVv+TQXLQIslOn2LntwRxfDUwBPab1H593VyxwnMBHD0lG5dZJu1z+lp1zXIIt2xRmkydPQGQHVfqVQrehBosmnqV9e0qjJQHJmlZ9BqP4mo/ZyqdqF8D1Y+oN0Rr4GugyxdV5v5yhO3jnbF3qg8MplXAQNN1PBFtYgcvqpwsppzP6spsDg755RCI5BTAYenMz9Gi6ogeMNub7lHlMCdJs6PxXp77W1UOloyc7F5KbvZcfr4kpRHZ1LtkiPgkwjOtxbT+eN4L4kvSsi68AEQ3eBkuSRlRkpItBa99SpK0q/kafnTrWpJk1EmtzFhjr89WK0maU5NvAEH9bIOl3uf947nRjsYWd56eJM2O6I1I8IwbWC5tnn0htO0j7nw9SUIOj0iwG1hObR7NLVa88UEn5wKSmXhsGz/Z3O0AyrW2kQ7xJjR9tueRpGONVTmEg+VKLC9vopiVGWuTsjyS1jDs5CMjmgcu4w4R7jYTLdfOkJTnCx/8r5Qxp8LUieoIxrtmSELXz//yJ79zhcjyliDimRmS3CEhYHt5U8rPngftu0hqoH+GpFQbqcEzrLhqH4vzU5rfHn81J4Fi+/TgzXbNik4mmpktL78+9hvd6W9l3nkjKQWsGEbCA7JdroVH0RJVoV1O/gUkpcJYs/ogA393QOVW88XQfmPf+T+dvD1JygsVQpFwQOVU81L7zahdl/c5hAdMXUbj0dOsvVON0NCEKtTgXFat09SEMPSw0TNw3G3mOZIOQITFDv5lbKdfUi2JqP5KcuwyRjw9m6DU+pKMHEj/QIjvudws2aYcDBQhz3Pe88NPHhMD9oAFrfwCvTxPXkQnfNNWqLjraRCrNoD9dxomP3sbcuc+L8JToQnfdvfVpc6fLdQA+K5Jx8Bsj73Mz7UlvZ1U3PY4VG3b67icqcf7X4LpL+gzkqIal2orxEbcnx7xsvadro5BJLbiGLfPO33tmudS5X3e15mV93dqu5ttwCO1V0VQYgORxGe/z4oQv4YVWbB+LWB1nae1vEKAqlpPXSAhwq+Rpvq3/LCBSEoHkdTQCT5kP/FzptLJew6amvBUk/kPwITpqQsiFALb5CD4YQOTlE4qhGjjB16+NdAsfHRkv3rf02jyiz5PeRAh53Iykho8NRdWi2RV98Av7NB3aqgCTn58eHo3pcn//zuFxk2YONkD2S/fVZn4ynlWZcMYDrSEAu2u7miUvHmFaY4O8JvMKrc8cBsF4LIGoCt8Vcef1YotvJf11vYMBSKpNZIyIUz+eEkIkhefxRWy+S7yr5II8v8PjUQEFJ5Hioy0SUo/xq2b+viX/Enhc8HFAmEPpoYuBw1UFEls/TDHj3s7ggaZTxyvr7OG8YTWQtZek+6ER+Mxftqnh9yyhW6HUWyu6Umf1olT1Eg6AcLV4Tjvct4HoAOa3/ojXYIyfEkjKR2MdTZvEDhlyPZCl8oqGMZk+opunP8AbpyniBK981EAAAAASUVORK5CYII=');
          background-repeat: no-repeat;
          background-size: contain;
          height: 2em;
          width: 2em;}

          span.success {
          color: green;
          }

          span.failed {
          color: red;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>
            <div class="logo">
              <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIAAAAAyCAYAAACUPNO1AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA6FpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYxIDY0LjE0MDk0OSwgMjAxMC8xMi8wNy0xMDo1NzowMSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDpFNTc2NDhFNjU0NTMxMUUzOTI4Nzk3OTY2NzEyMTNGQyIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpFNTc2NDhFNTU0NTMxMUUzOTI4Nzk3OTY2NzEyMTNGQyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBJbGx1c3RyYXRvciBDUzMiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0idXVpZDo1MGYxYjdlMS0zY2U3LTRkYjMtOTE5OS1lYTg0NTJhMWUxMmQiIHN0UmVmOmRvY3VtZW50SUQ9InV1aWQ6MzdEREQ1MzQ1NEUyREQxMUE4RTM4MzFGNDY1Q0I1NjMiLz4gPGRjOnRpdGxlPiA8cmRmOkFsdD4gPHJkZjpsaSB4bWw6bGFuZz0ieC1kZWZhdWx0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" alt="Citrix" height="30px" />
            </div>
            Citrix Optimizer Report
            <!--
            <div>
              <font size="-1">
                <xsl:value-of select="//starttime[1]" />
                (<xsl:value-of select="count(//result[.='1'])" /> optimized of <xsl:value-of select="count(//execute[.='1'])" />)
              </font>
            </div>
            -->
          </h1>
          <div class="hr-solid" />
          <table cellspacing="0" class="summary">
            <tr>
              <td>
                <h2>Template:</h2>
              </td>
              <td class="right">
                <h2>
                  <xsl:value-of select="metadata/displayname" />
                </h2>
              </td>
            </tr>
          </table>
          <div class="hotfix-col">
            <xsl:apply-templates select="metadata" />
            <div class="hr-solid" />
            <h2> Execution Summary </h2>
            <xsl:apply-templates select="run_status" />
            <div class="hr-solid" />
            <h2> Execution Details </h2>
            <xsl:apply-templates select="group" />
          </div>
          <div class="footer" />
        </div>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="metadata">
    <table cellspacing="0" class="summary">
      <tr>
        <td>
          <h2>Author:</h2>
        </td>
        <td class="right">
          <h2>
            <xsl:apply-templates select="author" />
          </h2>
        </td>
      </tr>
      <tr>
        <td>
          <h2>Category:</h2>
        </td>
        <td class="right">
          <h2>
            <xsl:value-of select="category" />
          </h2>
        </td>
      </tr>
      <tr>
        <td>
          <h2>Template Version:</h2>
        </td>
        <td class="right">
          <h2>
            <xsl:value-of select="version" />
          </h2>
        </td>
      </tr>
      <tr>
        <td>
          <h2>Description:</h2>
        </td>
        <td class="right">
          <h4>
            <xsl:apply-templates select="description" />
          </h4>
        </td>
      </tr>
    </table>
  </xsl:template>
  <xsl:template match="run_status">
    <table cellspacing="0">
      <tr>
        <td>
          <h3>Result:</h3>
        </td>
        <td class="right">
          <xsl:choose>
            <xsl:when test="run_successful = 'True'">
              <div class="success" />
              <span class="success"> Success! </span>
              <xsl:value-of select="run_details" />
            </xsl:when>
            <xsl:otherwise>
              <div class="failed" />
              <span class="failed"> Failed! </span>
              <xsl:value-of select="run_details" />
            </xsl:otherwise>
          </xsl:choose>
        </td>
      </tr>
      <tr>
        <td>
          <h3>Mode:</h3>
        </td>
        <td class="right">
          <h4>
            <xsl:value-of select="run_mode" />
          </h4>
        </td>
      </tr>
      <tr>
        <td>
          <h3>Success:</h3>
        </td>
        <td class="right">
            <xsl:value-of select="entries_success" /> / <xsl:value-of select="entries_total" />
        </td>
      </tr>
      <tr>
        <td>
          <h3>Failed:</h3>
        </td>
        <td class="right">
            <xsl:value-of select="entries_failed" />  / <xsl:value-of select="entries_total" />
        </td>
      </tr>
      <tr>
        <td>
          <h3>Skipped:</h3>
        </td>
        <td class="right">
          <xsl:value-of select="count(//entry/execute[text() = '0'])" /> / <xsl:value-of select="entries_total" />
        </td>
      </tr>
      <tr>
        <td>
          <h3>Optimizer Version:</h3>
        </td>
        <td class="right">
            <xsl:value-of select="optimizerversion" />
        </td>
      </tr>
      <tr>
        <td>
          <h3>Target Computer:</h3>
        </td>
        <td class="right">
          <xsl:value-of select="targetcomputer" />
        </td>
      </tr>
      <tr>
        <td>
          <h3>Target Computer OS:</h3>
        </td>
        <td class="right">
          <xsl:value-of select="targetos" />
        </td>
      </tr>
      <tr>
        <td>
          <h3>Start Time:</h3>
        </td>
        <td class="right">
          <xsl:variable name="starttime_left" select="substring-before(time_start, '_')" />
          <xsl:variable name="starttime_right" select="substring-after(time_start, '_')" />
          <xsl:variable name="startfinal_right">
            <xsl:call-template name="string-replace-all">
              <xsl:with-param name="text" select="$starttime_right" />
              <xsl:with-param name="replace" select="'-'" />
              <xsl:with-param name="by" select="':'" />
            </xsl:call-template>
          </xsl:variable>
          <xsl:value-of select="$starttime_left" />
          <xsl:text> </xsl:text>
          <xsl:value-of select="$startfinal_right" />
        </td>
      </tr>
      <tr>
        <td>
          <h3>End Time:</h3>
        </td>
        <td class="right">
          <xsl:variable name="endtime_left" select="substring-before(time_end, '_')" />
          <xsl:variable name="endtime_right" select="substring-after(time_end, '_')" />
          <xsl:variable name="endfinal_right">
            <xsl:call-template name="string-replace-all">
              <xsl:with-param name="text" select="$endtime_right" />
              <xsl:with-param name="replace" select="'-'" />
              <xsl:with-param name="by" select="':'" />
            </xsl:call-template>
          </xsl:variable>
          <xsl:value-of select="$endtime_left" />
          <xsl:text> </xsl:text>
          <xsl:value-of select="$endfinal_right" />
        </td>
      </tr>
    </table>
  </xsl:template>
  <xsl:template match="group">
    <p />
    <h3>
      <xsl:value-of select="displayname" />
    </h3>
    (<xsl:apply-templates select="description" />)
    <p />
    <table cellspacing="0">
      <tr>
        <th class="alt">
        </th>
        <th class="alt center" style="width:75%">
          Optimization
        </th>
        <th class="center" style="width:25%">
          Current status
        </th>
      </tr>
      <xsl:apply-templates select="entry" />
    </table>
  </xsl:template>
  <xsl:template match="entry">
    <tr class="entry">
      <td class="center">
        <xsl:choose>
          <xsl:when test="execute = 0">
            <input type="checkbox" disabled="true" />
          </xsl:when>
          <xsl:otherwise>
            <input type="checkbox" checked="true" disabled="true" />
          </xsl:otherwise>
        </xsl:choose>
      </td>
      <td>
        <h3>
          <xsl:value-of select="name" />
        </h3>
        <xsl:apply-templates select="description" />
      </td>
      <td class="center">
        <xsl:choose>
          <xsl:when test="execute = 0">
            -- Not Analyzed
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="history/return/result = 1">
                <div class="optimized" />
                Optimized
              </xsl:when>
              <xsl:otherwise>
                <div class="notoptimized" />
                Not Optimized
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </td>
    </tr>
    <!-- New section with detailed information -->
    <tr class="entry">
      <td class="center"></td>
      <td>
        <p>
          <b>Details: </b>
          <xsl:apply-templates select="history/return/details" />
        </p>
        <p>
          <b>Module type: </b>
          <xsl:value-of select="action/plugin" />
        </p>
        <xsl:choose>
          <xsl:when test="action/plugin = 'Registry'">
            <p>
              <b> - Key: </b>
              <xsl:value-of select="action/params/path" />
            </p>
            <p>
              <b> - Value: </b>
              <xsl:value-of select="action/params/name" /> (<xsl:value-of select="action/params/valuetype" />)
            </p>
            <p>
              <b> - Data: </b>
              <xsl:value-of select="action/params/value" />
            </p>
          </xsl:when>
          <xsl:when test="action/plugin = 'Services'">
            <p>
              <b> - Name: </b>
              <xsl:value-of select="action/params/name" />
            </p>
            <p>
              <b> - Value: </b>
              <xsl:value-of select="action/params/value" />
            </p>
          </xsl:when>
          <xsl:when test="action/plugin = 'UWP'">
            <p>
              <b> - Name: </b>
              <xsl:value-of select="action/params/name" />
            </p>
          </xsl:when>
          <xsl:when test="action/plugin = 'SchTasks'">
            <p>
              <b> - Location: </b>
              <xsl:value-of select="action/params/path" />
            </p>
            <p>
              <b> - Name: </b>
              <xsl:value-of select="action/params/name" />
            </p>
            <p>
              <b> - State: </b>
              <xsl:value-of select="action/params/value" />
            </p>
          </xsl:when>
          <xsl:when test="action/plugin = 'PowerShell'">
            <p>
              <b>PowerShell code is not included in generated HTML report. To see it, please review the configuration of original template</b>
            </p>
          </xsl:when>
          <xsl:otherwise>
            <p>
              <b>Unknown type of module, details are not available</b>
            </p>
          </xsl:otherwise>
        </xsl:choose>
      </td>
      <td></td>
    </tr>
  </xsl:template>
  <xsl:template match="text()" name="split">
    <xsl:param name="pText" select="."/>
    <xsl:if test="string-length($pText)">
      <xsl:if test="not($pText=.)">
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:variable name="item" select="substring-before(concat($pText,' '),' ')" />
      <xsl:variable name="loweritem" select="translate($item,'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
      <xsl:choose>
        <xsl:when test="contains($loweritem, 'http')">
          <xsl:variable name="itemleft" select="substring-before($loweritem, 'http')" />
          <xsl:choose>
            <xsl:when test="substring($loweritem, string-length($loweritem)) = ',' or substring($loweritem, string-length($loweritem)) = '.'">
              <xsl:variable name="itemright1" select="substring-after($loweritem, $itemleft)" />
              <xsl:variable name="itemright1_trim" select="substring($itemright1,0,string-length($itemright1))" />
              <span>
                <xsl:value-of select="$itemleft" />
              </span>
              <a href="{$itemright1_trim}" target="_blank">
                <xsl:value-of select="$itemright1_trim" />
              </a>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="itemright2" select="substring-after($loweritem, $itemleft)" />
              <span>
                <xsl:value-of select="$itemleft" />
              </span>
              <a href="{$itemright2}" target="_blank">
                <xsl:value-of select="$itemright2" />
              </a>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$item" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="split">
        <xsl:with-param name="pText" select="substring-after($pText, ' ')"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="string-replace-all">
    <xsl:param name="text" />
    <xsl:param name="replace" />
    <xsl:param name="by" />
    <xsl:choose>
      <xsl:when test="contains($text, $replace)">
        <xsl:value-of select="substring-before($text,$replace)" />
        <xsl:value-of select="$by" />
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text"
          select="substring-after($text,$replace)" />
          <xsl:with-param name="replace" select="$replace" />
          <xsl:with-param name="by" select="$by" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>