#!vanilla

pi = Math.PI

# work around unicode issue
char = (id, code) -> $(".#{id}").html "&#{code};"
char "deg", "deg"
char "percent", "#37"
char "equals", "#61"

# Import raw data
raw = $blab.resource "gamsatc_data"#;

data = (y: y, t: t for y, t of raw)

class d3Object

    constructor: (id) ->
        @element = d3.select "##{id}"
        @element.selectAll("svg").remove()
        @obj = @element.append "svg"
        @initAxes()
        
    append: (obj) -> @obj.append obj
    
    initAxes: ->

class Guide extends d3Object

    r = 10 # circle radius
    
    constructor: ()->
        
        # Initial positions
        @x1 = mx(-8) # circle1 x
        @y1 = my(1.4) # circle1 y
        @x2 = mx(-4) # circle2 x
        @y2 = my(0.4) # circle2 y
        @xl = mx(-9) # vertical dashed line
        @yl = my(1) # horizontal dashed line
        
        super "guide"

        @obj.attr('width', width)
            .attr('height', height)
            .attr("id", "guide")

        @obj.on("click", null)  # Clear any previous event handlers.
        #@obj.on("click", => @click())
        d3.behavior.drag().on("drag", null)  # Clear any previous event handlers.

        @space = @obj.append('g')
            .attr('width', width)
            .attr('height', height)
            .attr('id','space')

        @circle1 = @space.append("circle")
            .attr("transform", "translate(#{@x1}, #{@y1})")
            .attr("r", r)
            .attr("xx", @x1)
            .attr("yy", @y1)
            .attr("class", "modelcircle")
            
        @circle1.call(
            d3.behavior
            .drag()
            .on("drag", => @moveCircle(@circle1, d3.event.x, d3.event.y))
        )

        @circle2 = @space.append("circle")
            .attr("transform", "translate(#{@x2}, #{@y2})")
            .attr("r", r)
            .attr("xx", @x2)
            .attr("yy", @y2)
            .attr("class", "modelcircle")
            
        @circle2.call(
            d3.behavior
            .drag()
            .on("drag", => @moveCircle(@circle2, d3.event.x, d3.event.y))
        )

        # line connecting circles
        @line12 = @space.append("line")
            .attr("x1", @x1)
            .attr("y1", @y1)
            .attr("x2", @x2)
            .attr("y2", @y2)
            .attr("class", "modelline")

        # vertical dashed line
        @lineX = @space.append("line")
            .attr("x1", 0)
            .attr("y1", margin.top)
            .attr("x2", 0)
            .attr("y2", height + margin.top)
            .attr("class","guideline")
            .attr("transform", "translate(#{@x1}, #{0})")
            .attr("xx", @xl)
            .attr("yy", 0)
            .attr("style","cursor:crosshair")

        @lineX.call(
            d3.behavior
            .drag()
            .on("drag", => @moveLine(@lineX, d3.event.x, -1))
        )

        # horizontal dashed line
        @lineY = @space.append("line")
            .attr("x1", margin.left)
            .attr("y1", 0)
            .attr("x2", width + margin.left)
            .attr("y2", 0)
            .attr("class","guideline")
            .attr("transform", "translate(#{0}, #{@y2})")
            .attr("xx", 0)
            .attr("yy", @yl)
            .attr("style","cursor:crosshair")
        
        @lineY.call(
            d3.behavior
            .drag()
            .on("drag", => @moveLine(@lineY, -1, d3.event.y))
        )
 
    initAxes: ->
        @x = d3.scale.linear()
            .domain([(firstYear-zeroYear)/10, (lastYear-zeroYear)/10])
            .range([margin.left, margin.left+width]) 

        @y = d3.scale.linear()
            .domain([lowTemp, highTemp])
            .range([margin.top+height, margin.top])
   
    moveCircle: (circ, x, y) ->
        @dragslide(circ, x, y)
        x1 = @circle1.attr("xx")
        y1 = @circle1.attr("yy")
        x2 = @circle2.attr("xx")
        y2 = @circle2.attr("yy")
        @line12.attr("x1",x1)
            .attr("y1",y1)
            .attr("x2",x2)
            .attr("y2",y2)
        slope = (@y.invert(y2)-@y.invert(y1))/(@x.invert(x2)-@x.invert(x1))
        inter = @y.invert(y1)-slope*@x.invert(x1)
        d3.select("#equation").html(model_text([inter, slope]))

    moveLine: (line, x, y) ->
        @dragslide(line, x, y)
        xx = @lineX.attr("xx")
        yy = @lineY.attr("yy")
        d3.select("#intersection")
            .html(lines_text([@x.invert(xx), @y.invert(yy)]))

    dragslide: (obj, x, y) ->
        xx = 0
        yy = 0
        if x>0
            xx = Math.max(margin.left, Math.min(width+margin.left, x))
        if y>0
            yy = Math.max(margin.top, Math.min(height+margin.top, y))
        obj.attr "transform", "translate(#{xx}, #{yy})"
        obj.attr("xx", xx)
        obj.attr("yy", yy)

    model_text = (p) ->
        a = (n) -> Math.round(100*p[n])/100
        s = (n) -> "<span style='color:green;font-size:14px'>#{a(n)}</span>"
        tr = (td1, td2) -> 
            "<tr><td style='text-align:right;'>#{td1}</td><td>#{td2}</td><tr/>"
        """
        <table class='func'>
        Model:
        #{tr "a = ", s(1)}
        #{tr "b = ", s(0)}
        </table>
        """    

    lines_text = (p) ->
        a = (n) -> Math.round(100*p[n])/100
        s = (n) -> "<span style='color:red;font-size:14px'>#{a(n)}</span>"
        tr = (td1, td2) -> 
            "<tr><td style='text-align:right;'>#{td1}</td><td>#{td2}</td><tr/>"
        """
        <table class='func'>
        Crosshair:
        #{tr "x = ", s(0)}
        #{tr "T = ", s(1)}
        </table>
        """    

class Plot extends d3Object

    constructor: (@data) ->
        
        super "plot"
        @obj.attr("id", "plot")
            .attr('width', width)
            .attr('height', height)

        plot = @obj.append('g')
            .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
            .attr('width', width)
            .attr('height', height)
            .attr('id','plot')

        plot.append("g")
            .attr("id","x-axis")
            .attr("class", "axis")
            .attr("transform", "translate(0, #{height+20})")
            .call(@xAxis)

        plot.append("g")
            .attr("id","x2-axis")
            .attr("class", "axis")
            .attr("transform", "translate(0, #{height+90})")
            .call(@x2Axis)

        plot.append("g")
            .attr("id","y-axis")
            .attr("class", "axis")
            .attr("transform", "translate(-10, 0)")
            .call(@yAxis)

        pline = d3.svg.line()
            .x((d) => @x(d.y))
            .y((d) => @y(d.t))

        plot.append("path")
            .datum(@data)
            .attr("class", "line")
            .attr("d", pline)

    initAxes: ->
        @x = d3.scale.linear()
            .domain([firstYear, lastYear])
            .range([0, width]) 

        @x2 = d3.scale.linear()
            .domain([(firstYear-zeroYear)/10, (lastYear-zeroYear)/10])
            .range([0, width]) 

        @y = d3.scale.linear()
            .domain([lowTemp, highTemp])
            .range([height, 0])
            
        @xAxis = d3.svg.axis()
            .scale(@x)
            .orient("bottom")
            .tickFormat(d3.format("d"))

        @x2Axis = d3.svg.axis()
            .scale(@x2)
            .orient("bottom")

        @yAxis = d3.svg.axis()
            .scale(@y)
            .orient("left")
   
 
class Demo

    constructor: ->
        @R = 4
        @xc1= parseFloat(guide.circle1.attr("xx")) - @R
        @yc1 = parseFloat(guide.circle1.attr("yy"))
        @xc2 = parseFloat(guide.circle2.attr("xx")) 
        @yc2 = parseFloat(guide.circle2.attr("yy")) - @R
        @xl = parseFloat(guide.lineX.attr("xx"))
        @yl = parseFloat(guide.lineY.attr("yy"))
        @p = 0
        
        @animate()
        
    snapshot: () ->
        @p += pi/100
        d1 = @R*Math.cos(@p)
        d2 = @R*(Math.sin(@p) + Math.sin(2*@p))
        if @p > 2*pi then @stop()

        guide.moveCircle(guide.circle1, @xc1 + d1, @yc1 + d2)
        guide.moveCircle(guide.circle2, @xc2 + d2, @yc2 + d1)
        guide.moveLine(guide.lineX, @xl+d1, -1)
        guide.moveLine(guide.lineY, -1, @yl+d2)

    animate:  () ->
        @timer = setInterval (=> @snapshot()), 5

    stop: ->
        clearInterval @timer
        @timer = null

class Solution1

    constructor: ->
        
        # animation steps
        @count = 0
        @N = 100
        
        # circle positions -> pixels
        @xc1= parseFloat(guide.circle1.attr("xx"))
        @yc1 = parseFloat(guide.circle1.attr("yy"))
        @xc2 = parseFloat(guide.circle2.attr("xx")) 
        @yc2 = parseFloat(guide.circle2.attr("yy"))
        @xc1Final = mx(0)
        @yc1Final = my(0.05)
        @xc2Final = mx(10)
        @yc2Final = my(1.05)

        # linearly interpolate between initial and final positions
        # slopes
        @a1 = (@yc1Final-@yc1)/(@xc1Final-@xc1) 
        @a2 = (@yc2Final-@yc2)/(@xc2Final-@xc2)
        # steps
        @dx1 = (@xc1Final - @xc1)/@N # step
        @dx2 = (@xc2Final - @xc2)/@N
        @dy1 = @a1 * @dx1
        @dy2 = @a2 * @dx2

        # initial circle positions
        guide.moveCircle(guide.circle1, @xc1, @yc1)
        guide.moveCircle(guide.circle2, @xc2, @yc2)

        @animate1()

    snapshot1: () ->
        if @count != @N
            @xc1 += @dx1
            @yc1 += @dy1
            @count += 1
            guide.moveCircle(guide.circle1, @xc1, @yc1)
        else
            @count = 0
            @stop()
            @animate2()

    snapshot2: () ->
        if @count != @N
            @xc2 += @dx2
            @yc2 += @dy2
            @count += 1
            guide.moveCircle(guide.circle2, @xc2, @yc2)
        else @stop()

    animate1:  () ->
        @timer = setInterval (=> @snapshot1()), 10

    animate2:  () ->
        @timer = setInterval (=> @snapshot2()), 10

    stop: ->
        clearInterval @timer
        @timer = null

class Example

    constructor: (@xlFinal, @ylFinal)->
        
        # animation steps
        @count = 0
        @N = 100
        
        # line positions -> pixels
        @xl = parseFloat(guide.lineX.attr("xx"))
        @yl = parseFloat(guide.lineY.attr("yy"))

        # interpolation steps
        @dxl = (@xlFinal - @xl)/@N
        @dyl = (@ylFinal - @yl)/@N

        # initial guide position
        guide.moveLine(guide.lineX, @xl, -1)
        guide.moveLine(guide.lineY, -1, @yl)

        @animateX() # animate vertical line first
        
    snapshotX: () ->
        if @count != @N
            @count += 1
            @xl += @dxl
            guide.moveLine(guide.lineX, @xl, -1)
        else 
            @count = 0
            @stop()
            @animateY()

    snapshotY: () ->
        if @count != @N
            @count +=1
            @yl += @dyl
            guide.moveLine(guide.lineY, -1, @yl)
        else @stop()

    animateX:  () ->
        @timer = setInterval (=> @snapshotX()), 10

    animateY:  () ->
        @timer = setInterval (=> @snapshotY()), 10

    stop: ->
        clearInterval @timer
        @timer = null


margin = {top: 40, right: 130, bottom: 160, left: 120}
width = 960 - margin.left - margin.right
height = 480 - margin.top - margin.bottom;

firstYear = 1850
zeroYear = 1960
lastYear = 2070
lowTemp = -0.6
highTemp = 1.6

mx = d3.scale.linear()
    .domain([(firstYear-zeroYear)/10, (lastYear-zeroYear)/10])
    .range([margin.left, margin.left+width]) 

my = d3.scale.linear()
    .domain([lowTemp, highTemp])
    .range([margin.top+height, margin.top])

new Plot data
guide = new Guide
new Demo

d3.selectAll("#example").on "click", -> new Example mx(0), my(0.05)
d3.selectAll("#solution1").on "click", -> new Solution1
d3.selectAll("#solution2").on "click", -> new Example mx(9), my(0.95)


