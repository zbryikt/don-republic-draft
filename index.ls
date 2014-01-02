angular.module 'main', <[firebase]>
.factory \DataService, ($firebase) ->
  ret = {}
  ret.user = null
  ret.db-ref = new Firebase \https://don.firebaseio.com
  ret.firebase = $firebase ret.db-ref
  ret.auth = new FirebaseSimpleLogin ret.db-ref, (e,u) ->
    for f in ret.handle[\user.changed] => f u
    ret.user = u
    console.log u
  ret.handle = {}
  ret.on = (n,f) -> ret.handle.[][n].push f

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
      ret.name.add it.name, name, n.name!, \name
      n
    factory: -> {}

  ret.user = base \user
  ret.group = base \group
  ret.proposal = base \proposal
  ret.plan = base \plan
  ret.comment = base \comment

  ret

ctrl = {}
ctrl.main = ($scope, DataService) ->
  DataService.on \user.changed, (u) -> $scope.$apply -> $scope.user = u

ctrl.user = ($scope,DataService) ->
  $scope <<< ctrl.base $scope, DataService, \user
  $scope <<<
    login: ->
      DataService.auth.login \facebook
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
  create-under: (type, id, ref) ->
    $scope.cur[type] = id
    item = $scope.create!
    console.log ref
    ref.[][ctrl-name].push item.name!
    DS[type]ref.$save!
  delete: -> DS[ctrl-name]ref.$remove(it)
  delete-under: (it, ref) ->
    obj = ref.[][ctrl-name]
    if it in obj => obj.splice obj.indexOf(it), 1
    $scope.delete it
  get: (name, id) -> DS[name]ref[id] or {}
  vote: (p,d) ->
    #if not (id = if DS.user => that.id) => return
    id = if DS.user => that.id else 0
    if id in (p.{}vote[d] or []) => p.vote[d]splice p.vote[d]indexOf(id), 1
    else if id in ((for it in [0 1 2]=>p.{}vote[it] or [])reduce (-> &0 ++ &1),[]) => return
    else p.{}vote.[][d].push id
    DS[ctrl-name]ref.$save!
  admin: (g, u, lv=1) ->
    if u in g.admin => delete g.admin
    else g.admin[u] = lv
    $scope.list.$save!
  list: DS[ctrl-name]ref
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
    p.plan.filter -> !picked xor (it in p.{}stand.[][user.id])
  $scope.pick = (p,k) ->
    user = DataService.user or {}
    if not user => return
    obj = p.{}stand.[][user.id]
    if k in obj => obj.splice obj.indexOf(k), 1 else => obj.push k
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
