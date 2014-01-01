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

  base = (name) -> do
    ref: $firebase new Firebase "https://don.firebaseio.com/#{name}"
    create: -> @ref.$add(it <<< {creator: ret.user, id: @ref.length + 1})
    factory: -> {}

  ret.user = base \user
  ret.group = base \group
  ret.proposal = base \proposal
  ret.strategy = base \strategy

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
    $scope.update u

ctrl.base = ($scope, DS, ctrl-name) -> do
  create: ->
    ret = DS[ctrl-name]create $scope.cur
    $scope.cur = DS[ctrl-name]factory!
    ret
  get: (name, id) -> DS[name]ref[id] or {}
  delete: -> DS[ctrl-name]ref.$remove(it)
  update: ->
  vote: (p,d) ->
    if not (id = if DS.user => that.id else) => return
    if id in (p.{}vote[d] or []) => p.vote[d]splice p.vote[d]indexOf(id), 1
    else if id in ((for it in [0 1 2]=>p.{}vote[it] or [])reduce (-> &0 ++ &1),[]) => return
    else p.{}vote.[][d].push id
    DS[ctrl-name]ref.$save!
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

ctrl.strategy = ($scope, DataService) ->
  $scope <<< ctrl.base $scope, DataService, \strategy
  $scope.create-under = (k,p) ->
    item = $scope.create!
    item.proposal = k
    p.[]strategy.push item.name!
    DataService.proposal.ref.$save!
  $scope.purge = ->
    obj = (DataService.proposal.[]strategy[it] or [])
    if it in obj =>
      obj.splice obj.indexOf(it),1
      DataServie.proposal.ref.$save!
    $scope.delete!

