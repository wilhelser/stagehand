(($) ->

  $.fn.selectorText = () ->
    selector = "%#{@[0].tagName.toLowerCase()}"
    @attr('id') && selector += "##{@.attr('id')}"
    @attr('class') && selector += ".#{@.attr('class')}"
    text = if @text().length > 30 then "#{@text().slice(0, 30)}..." else @text()
    selector = selector + " with text of '#{text}'"

  $.fn.shouldHaveValue = (val, msg) ->
    equal @.val(), val, msg or "#{@selectorText()} should have a value of #{val}"
    @

  $.fn.shouldBe = (attr, msg) ->
    ok @.is(attr), msg or "#{@selectorText()} should be #{attr}"
    @

  $.fn.shouldNotBe = (attr, msg) ->
    ok !@.is(attr), msg or "#{@selectorText()} should not be #{attr}"
    @

  $.fn.shouldSay = (text, msg) ->
    equal @text(), text, msg or "#{text} is displayed within #{@selectorText()}"
    @

  fixture =
    fixture: ->
      $("#qunit-fixture")
    buildElements: ->
      $set = $()
      for el, text in elements
        if typeof text == "String"
          $set.add($("<div />").text(text))
        else
          $set.add($("<div />").append(@buildElements(text)))
      $set
    generate: (elements) ->
      @$el.append @buildElements(elements)
    get: ->
      @$el && @$el.data('stagehand')
    use: (selector) ->
      @fixture().children().not(selector).remove()
    reset: ->
      @get() && @get().teardown()
    select: (stage, scene) ->
      if typeof stage == 'number'
        @get().$controls.find('li').eq(stage).find('li').eq(scene).find('a').click()
      else
        @get().$controls.find("[data-stage='#{stage}']").find("li").eq(scene).find("a").click()
    init: (opts, $context) ->
      $context ?= $(document.body)
      @$el = $context.stagehand(opts)
      @

  QUnit.testDone -> fixture.reset.apply(fixture)

  test 'it chains properly', ->
    deepEqual fixture.init().$el.hide().show(), $(document.body), '.stagehand() returns proper element'

  test 'it produces a Stage object', ->
    sc = fixture.init().get()
    deepEqual sc.$el.hide().show(), $(document.body), "stagehand().data('stagehand') returns stagehand object"
  
  test 'it appends controls to the body', ->
    sc = fixture.init().get()
    sc.$controls.shouldBe('#stagehand-controls')
    sc.$controls.parent().shouldBe($(document.body), 'controls should be appended to body')
  
  test 'it detects siblings with `data-stage` attributes as one scene', ->
    fixture.use '.direct_siblings'
    sc = fixture.init().get()
    equal sc.$controls.find('> ul > li').length, 1, 'one scene control built'
    sc.$controls.find('> ul > li > ul > li a.stagehand-active').shouldSay('1')
    equal sc.$controls.find('li li').length, 2, 'scene control has two options'
    equal sc.stages.length, 1, 'one stage in stagehand.stages array'

  test 'it shows the first scene of each stage by default', ->
    fixture.use '.direct_siblings'
    sc = fixture.init().get()
    sc.stages[0].eq(0).shouldBe(':visible')
    sc.stages[0].eq(1).shouldNotBe(':visible')

  test 'changing a stage control to a new scene changes the associated stage', ->
    fixture.use '.direct_siblings'
    sc = fixture.init().get()
    fixture.select(0, 1)
    sc.stages[0].eq(0).shouldNotBe(':visible')
    sc.stages[0].eq(1).shouldBe(':visible')

  test 'support named `data-stage` attributes', ->
    fixture.use '.named_stages'
    sc = fixture.init().get()
    equal sc.stages.length, 3, '3 stages in stagehand.stages array'
    sc.$controls.find("[data-stage='foo'] h2").shouldSay('foo')
    fixture.select('foo', 1)
    fixture.select('bar', 2)
    sc.named_stages['foo'].eq(0).shouldNotBe(':visible')
    sc.named_stages['foo'].eq(1).shouldBe(':visible')
    sc.named_stages['bar'].eq(1).shouldNotBe(':visible')
    sc.named_stages['bar'].eq(2).shouldBe(':visible')

  test 'support named `data-scene` attributes', ->
    fixture.use '.named_scenes'
    sc = fixture.init().get()
    equal sc.stages.length, 2, '2 stages detected'
    sc.$controls.find("[data-stage='foo'] a.stagehand-active").shouldSay('my scene')
    sc.$controls.find("[data-stage='Stage 2'] a.stagehand-active").shouldSay('1')
    fixture.select('foo', 1)
    fixture.select('Stage 2', 1)
    sc.$controls.find("[data-stage='foo'] a.stagehand-active").shouldSay('2')
    sc.$controls.find("[data-stage='Stage 2'] a.stagehand-active").shouldSay('my other scene')

  test 'support multiple named `data-scene` attributes', ->
    fixture.use '.shared_scenes'
    sc = fixture.init().get()
    $stage = sc.named_stages['foo']
    fixture.$el.find('.actor_1').shouldBe(':visible')
    fixture.$el.find('.actor_2').shouldNotBe(':visible')
    fixture.$el.find('.actor_3').shouldNotBe(':visible')
    fixture.$el.find('.actor_4').shouldBe(':visible')
    fixture.select('foo', 1)
    fixture.$el.find('.actor_1').shouldNotBe(':visible')
    fixture.$el.find('.actor_2').shouldBe(':visible')
    fixture.$el.find('.actor_3').shouldNotBe(':visible')
    fixture.$el.find('.actor_4').shouldBe(':visible')
    fixture.select('foo', 2)
    fixture.$el.find('.actor_1').shouldNotBe(':visible')
    fixture.$el.find('.actor_2').shouldNotBe(':visible')
    fixture.$el.find('.actor_3').shouldBe(':visible')
    fixture.$el.find('.actor_4').shouldNotBe(':visible')

)(jQuery)