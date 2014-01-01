// Generated by LiveScript 1.2.0
var ctrl;
angular.module('main', ['firebase']).factory('DataService', function($firebase){
  var ret, base;
  ret = {};
  ret.user = null;
  ret.dbRef = new Firebase('https://don.firebaseio.com');
  ret.firebase = $firebase(ret.dbRef);
  ret.auth = new FirebaseSimpleLogin(ret.dbRef, function(e, u){
    var i$, ref$, len$, f;
    for (i$ = 0, len$ = (ref$ = ret.handle['user.changed']).length; i$ < len$; ++i$) {
      f = ref$[i$];
      f(u);
    }
    ret.user = u;
    return console.log(u);
  });
  ret.handle = {};
  ret.on = function(n, f){
    var ref$;
    return ((ref$ = ret.handle)[n] || (ref$[n] = [])).push(f);
  };
  base = function(name){
    return {
      ref: $firebase(new Firebase("https://don.firebaseio.com/" + name)),
      create: function(it){
        return this.ref.$add((it.creator = ret.user, it.id = this.ref.length + 1, it));
      },
      factory: function(){
        return {};
      }
    };
  };
  ret.user = base('user');
  ret.group = base('group');
  ret.proposal = base('proposal');
  ret.strategy = base('strategy');
  return ret;
});
ctrl = {};
ctrl.main = function($scope, DataService){
  return DataService.on('user.changed', function(u){
    return $scope.$apply(function(){
      return $scope.user = u;
    });
  });
};
ctrl.user = function($scope, DataService){
  import$($scope, ctrl.base($scope, DataService, 'user'));
  $scope.login = function(){
    return DataService.auth.login('facebook');
  };
  $scope.logout = function(){
    return DataService.auth.logout('facebook');
  };
  return DataService.on('user.changed', function(u){
    $scope.$apply(function(){
      return $scope.cur = u;
    });
    return $scope.update(u);
  });
};
ctrl.base = function($scope, DS, ctrlName){
  return {
    create: function(){
      var ret;
      ret = DS[ctrlName].create($scope.cur);
      $scope.cur = DS[ctrlName].factory();
      return ret;
    },
    get: function(name, id){
      return DS[name].ref[id] || {};
    },
    'delete': function(it){
      return DS[ctrlName].ref.$remove(it);
    },
    update: function(){},
    vote: function(p, d){
      var id, that, it, ref$;
      if (!(id = (that = DS.user) ? that.id : void 8)) {
        return;
      }
      if (in$(id, (p.vote || (p.vote = {}))[d] || [])) {
        p.vote[d].splice(p.vote[d].indexOf(id), 1);
      } else if (in$(id, (function(){
        var i$, ref$, len$, results$ = [];
        for (i$ = 0, len$ = (ref$ = [0, 1, 2]).length; i$ < len$; ++i$) {
          it = ref$[i$];
          results$.push((p.vote || (p.vote = {}))[it] || []);
        }
        return results$;
      }()).reduce(function(){
        return arguments[0].concat(arguments[1]);
      }, []))) {
        return;
      } else {
        ((ref$ = p.vote || (p.vote = {}))[d] || (ref$[d] = [])).push(id);
      }
      return DS[ctrlName].ref.$save();
    },
    list: DS[ctrlName].ref,
    cur: DS[ctrlName].factory()
  };
};
ctrl.group = function($scope, DataService){
  import$($scope, ctrl.base($scope, DataService, 'group'));
  return $scope.addMember = function(g){
    (g.users || (g.users = {}))[g.newMember] = 1;
    g.newMember = "";
    return $scope.list.$save();
  };
};
ctrl.proposal = function($scope, DataService){
  return import$($scope, ctrl.base($scope, DataService, 'proposal'));
};
ctrl.strategy = function($scope, DataService){
  import$($scope, ctrl.base($scope, DataService, 'strategy'));
  $scope.createUnder = function(k, p){
    var item;
    item = $scope.create();
    item.proposal = k;
    (p.strategy || (p.strategy = [])).push(item.name());
    return DataService.proposal.ref.$save();
  };
  return $scope.purge = function(it){
    var obj, ref$;
    obj = ((ref$ = DataService.proposal).strategy || (ref$.strategy = []))[it] || [];
    if (in$(it, obj)) {
      obj.splice(obj.indexOf(it), 1);
      DataServie.proposal.ref.$save();
    }
    return $scope['delete']();
  };
};
function import$(obj, src){
  var own = {}.hasOwnProperty;
  for (var key in src) if (own.call(src, key)) obj[key] = src[key];
  return obj;
}
function in$(x, xs){
  var i = -1, l = xs.length >>> 0;
  while (++i < l) if (x === xs[i]) return true;
  return false;
}