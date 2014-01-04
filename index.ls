angular.module 'main', <[firebase]>
.directive \contenteditable, ->
  require: \ngModel
  scope: ngModel: \=
  link: (scope, e, attrs, ctrl) ->
    e.on \keyup, -> scope.$apply -> scope.ng-model = e.html!
    scope.$watch 'ngModel', -> e.html scope.ng-model
.filter \type, -> (d, type) -> (d or [])filter(-> it.t == type)
.filter \picked, (DataService) ->
  (d=[], p, picked=true) ->
    stand = p.{}stand.[][(DataService.user or {})id]
    d.filter(-> !picked xor (it.id in stand))sort (a,b) -> stand.indexOf(a) - stand.indexOf(b)
.factory \DataService, ($firebase) ->
  ret = {}
  ret.user = null
  ret.db-ref = new Firebase \https://don.firebaseio.com
  ret.firebase = $firebase ret.db-ref
  ret.auth = new FirebaseSimpleLogin ret.db-ref, (e,u) ->
    ret.user = u
    for f in ret.handle[\user.changed] => f u
  ret.handle = {}
  ret.on = (n,f) -> ret.handle.[][n].push f

  # a and b: {t: \type, id: \id}
  ret.link = (cat, a, b, dir, name=null) ->
    ls = [a,b]map -> it.v.{}link.[][cat]
    lk = [b,a]map -> {} <<< it{id,t} <<< {d: dir * (2 * &1 - 1),n: name}
    ls.map (n,i)-> if <[t id d n]>map(-> n[it]==lk[i][it])filter(->!it)length>0 => n.push lk[i]
    [a,b]map (it,i) ->
      if not ret[it.t]ref[it.id] => ret[it.t]ref[it.id] = it.v
      else ret[it.t]ref[it.id].{}link[cat] = ls[i]
    [a,b]map -> ret[it.t]ref.$save!

  ret.name = do
    ref: $firebase new Firebase \https://don.firebaseio.com/name
    add: (n, type, id, field) ->
      if @ref.{}n.[][n]filter(-> it.type==type and it.id==id)length => return
      @ref.n.[][n]push {type,id,field}
      if not (type of @ref.{}t) => @ref.t[type] = 1
      @ref.$save!
    prune: (n) ->
      @ref.n[n] = @ref.n.[][n]map(->
        try if ret[it.type][it.id][it.field]!=n => throw \changed
        catch => it.id = null
        it
      )filter -> it and it.id
      @ref.$save!

  base = (name) -> do
    ref: $firebase new Firebase "https://don.firebaseio.com/#{name}"
    create: ->
      n = @ref.$add(it <<< {creator: ret.user, create_time: new Date!getTime!})
      it.id = n.name!
      ret.name.add it.name, name, n.name!, \name
      it

    factory: -> {}

  ret.user = base \user
  ret.group = base \group
  ret.proposal = base \proposal
  ret.plan = base \plan
  ret.comment = base \comment
  ret.issue = base \issue

  ret

ctrl = {}
ctrl.main = ($scope, DataService) ->
  DataService.on \user.changed, (u) -> $scope.$apply -> $scope.user = u

ctrl.user = ($scope,DataService) ->
  $scope <<< ctrl.base $scope, DataService, \user
  $scope <<<
    login: -> DataService.auth.login \facebook
    logout: -> DataService.auth.logout \facebook
  DataService.on \user.changed, (u) ->
    $scope.$apply -> $scope.cur = u

ctrl.name = ($scope, $timeout, DataService) ->
  $scope.data = DataService.name.ref
  $scope.handle = null
  $scope.keyword = ""
  search = ->
    $scope.result = [k for k of $scope.data.n]filter(->it.indexOf($scope.keyword)>=0)map ->
      DataService.name.prune it
      {name: it, list: $scope.data.n[it]}
    $scope.handle = null

  $scope.$watch "keyword", ->
    if $scope.handle => $timeout.cancel $scope.handle
    $scope.handle = $timeout search, 500


ctrl.base = ($scope, DS, ctrl-name) -> do
  create: (t,k,p) ->
    ret = DS[ctrl-name]create $scope.cur
    $scope.cur = DS[ctrl-name]factory!
    ret
  create-with: (cat, type, id, ref) ->
    item = $scope.create!
    DS.link cat, {id,t:type,v:ref}, {t:ctrl-name,id:item.id,v:item}, 1
    item

  create-under: (type, id, ref) ->
    $scope.cur[type] = id
    item = $scope.create!
    console.log ref
    ref.[][ctrl-name].push item.id
    DS[type]ref.$save!
  delete: (key) ->
    if (!DS.user and DS[ctrl-name]ref[key]creator) or (DS.user and DS.user.id != DS[ctrl-name]ref[key].{}creator.id) => return
    types = {}
    for cat,links of DS[ctrl-name]ref[key]link
      for des in links
        obj = @get(des.t, des.id)
        ret = obj.link[cat]map((d,i) -> if d.id==key => null else d)filter(->it)
        if ret.length != obj.link[cat] =>
          obj.link[cat] = ret
          types[des.t] = 1
    DS[ctrl-name]ref.$remove(key)
    for it of types => if it!=ctrl-name => DS[it]ref.$save!
  delete-under: (it, ref) ->
    obj = ref.[][ctrl-name]
    if it in obj => obj.splice obj.indexOf(it), 1
    $scope.delete it
  get: (type, id) -> DS[type]ref[id] or {}
  vote: (p,d) ->
    #if not (id = if DS.user => that.id) => return
    id = if DS.user => that.id else 0
    if !p.{}config.{}vote.allow-anonymous and !id => return
    if id in (p.{}vote[d] or []) => p.vote[d]splice p.vote[d]indexOf(id), 1
    else if id in ((for it in [0 1 2]=>p.{}vote[it] or [])reduce (-> &0 ++ &1),[]) => return
    else p.{}vote.[][d].push id
    DS[ctrl-name]ref.$save!
  admin: (g, u, lv=1) ->
    if u in g.admin => delete g.admin
    else g.admin[u] = lv
    $scope.list.$save!
  save: (k) -> DS[ctrl-name]ref.$save!
  list: DS[ctrl-name]ref
  links: (p, cat, type=null) ->
    ret = p.{}link[cat] or []
    if type => ret = ret.filter -> it.t == type
    ret.map ~> @get it.t, it.id
  cur: DS[ctrl-name]factory!

ctrl.group = ($scope, DataService) ->
  $scope <<< ctrl.base $scope, DataService, \group
  $scope.add-member = (g) ->
    g.{}users[g.new-member] = 1
    g.new-member = ""
    $scope.list.$save!

ctrl.proposal = ($scope, DataService) ->
  $scope <<< ctrl.base $scope, DataService, \proposal
  $scope.picked = (p, picked=true) ->
    user = DataService.user or {}
    stand = p.{}stand.[][user.id]
    p.[]plan.filter(-> !picked xor (it in stand))sort (a,b) -> stand.indexOf(a) - stand.indexOf(b)
  $scope.pick = (p,k) ->
    user = DataService.user or {}
    p.{}config.{}vote
    if not (p.config.vote.allow-anonymous or user.id) => return
    obj = p.{}stand.[][user.id]
    if k in obj => obj.splice obj.indexOf(k), 1 else =>
      if p.config.vote.choice == \1 and obj.length > 0 => obj.pop!
      obj.push k
    $scope.list.$save!

ctrl.plan = ($scope, DataService) ->
  $scope <<< ctrl.base $scope, DataService, \plan
  $scope.purge = ->
    pk = $scope.get(\plan, it)proposal
    obj = (DataService.proposal.ref[pk] or {}).[]plan
    if it in obj =>
      obj.splice obj.indexOf(it),1
      DataService.proposal.ref.$save!
    $scope.delete it

ctrl.comment = ($scope, DataService) ->
  $scope <<< ctrl.base $scope, DataService, \comment

ctrl.issue = ($scope, DataService) ->
  $scope <<< ctrl.base $scope, DataService, \issue
