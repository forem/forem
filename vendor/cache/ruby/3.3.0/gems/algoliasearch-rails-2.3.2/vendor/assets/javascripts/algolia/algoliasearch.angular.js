/*
 * Copyright (c) 2013 Algolia
 * http://www.algolia.com/
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

var ALGOLIA_VERSION = '2.9.7';

/*
 * Copyright (c) 2013 Algolia
 * http://www.algolia.com/
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

/*
 * Algolia Search library initialization
 * @param applicationID the application ID you have in your admin interface
 * @param apiKey a valid API key for the service
 * @param methodOrOptions the hash of parameters for initialization. It can contains:
 *        - method (optional) specify if the protocol used is http or https (http by default to make the first search query faster).
 *          You need to use https is you are doing something else than just search queries.
 *        - hosts (optional) the list of hosts that you have received for the service
 *        - dsn (optional) set to true if your account has the Distributed Search Option
 *        - dsnHost (optional) override the automatic computation of dsn hostname
 */
var AlgoliaSearch = function(applicationID, apiKey, methodOrOptions, resolveDNS, hosts) {
  var self = this;
  this.applicationID = applicationID;
  this.apiKey = apiKey;
  this.dsn = true;
  this.dsnHost = null;
  this.hosts = [];
  this.currentHostIndex = 0;
  this.requestTimeoutInMs = 2000;
  this.extraHeaders = [];
  this.jsonp = null;
  this.options = {};

  // make sure every client instance has it's own cache
  this.cache = {};

  var method;
  var tld = 'net';
  if (typeof methodOrOptions === 'string') { // Old initialization
    method = methodOrOptions;
  } else {
    // Take all option from the hash
    var options = methodOrOptions || {};
    this.options = options;
    if (!this._isUndefined(options.method)) {
      method = options.method;
    }
    if (!this._isUndefined(options.tld)) {
      tld = options.tld;
    }
    if (!this._isUndefined(options.dsn)) {
      this.dsn = options.dsn;
    }
    if (!this._isUndefined(options.hosts)) {
      hosts = options.hosts;
    }
    if (!this._isUndefined(options.dsnHost)) {
      this.dsnHost = options.dsnHost;
    }
    if (!this._isUndefined(options.requestTimeoutInMs)) {
      this.requestTimeoutInMs = +options.requestTimeoutInMs;
    }
    if (!this._isUndefined(options.jsonp)) {
      this.jsonp = options.jsonp;
    }
  }
  // If hosts is undefined, initialize it with applicationID
  if (this._isUndefined(hosts)) {
    hosts = [
      this.applicationID + '-1.algolianet.com',
      this.applicationID + '-2.algolianet.com',
      this.applicationID + '-3.algolianet.com'
    ];
  }
  // detect is we use http or https
  this.host_protocol = 'http://';
  if (this._isUndefined(method) || method === null) {
    this.host_protocol = ('https:' == document.location.protocol ? 'https' : 'http') + '://';
  } else if (method === 'https' || method === 'HTTPS') {
    this.host_protocol = 'https://';
  }
  // Add protocol to hosts
  for (var i = 0; i < hosts.length; ++i) {
    this.hosts.push(this.host_protocol + hosts[i]);
  }
  // then add Distributed Search Network host if there is one
  if (this.dsn || this.dsnHost != null) {
    if (this.dsnHost) {
      this.hosts.unshift(this.host_protocol + this.dsnHost);
    } else {
      this.hosts.unshift(this.host_protocol + this.applicationID + '-dsn.algolia.' + tld);
    }
  }
  // angular dependencies injection
  if (this.options.angular) {
    this.options.angular.$injector.invoke(['$http', '$q', function ($http, $q) {
      self.options.angular.$q = $q;
      self.options.angular.$http = $http;
    }]);
  }

  this._ua = this.options._ua || 'Algolia for vanilla JavaScript ' + window.ALGOLIA_VERSION;
};

// This holds the number of JSONP requests done accross clients
// It's used as part of the ?callback=JSONP_$JSONPCounter when we do JSONP requests
AlgoliaSearch.JSONPCounter = 0;

function AlgoliaExplainResults(hit, titleAttribute, otherAttributes) {

  function _getHitExplanationForOneAttr_recurse(obj, foundWords) {
    var res = [];
    if (typeof obj === 'object' && 'matchedWords' in obj && 'value' in obj) {
      var match = false;
      for (var j = 0; j < obj.matchedWords.length; ++j) {
        var word = obj.matchedWords[j];
        if (!(word in foundWords)) {
          foundWords[word] = 1;
          match = true;
        }
      }
      if (match) {
        res.push(obj.value);
      }
    } else if (Object.prototype.toString.call(obj) === '[object Array]') {
      for (var i = 0; i < obj.length; ++i) {
        var array = _getHitExplanationForOneAttr_recurse(obj[i], foundWords);
        res = res.concat(array);
      }
    } else if (typeof obj === 'object') {
      for (var prop in obj) {
        if (obj.hasOwnProperty(prop)){
          res = res.concat(_getHitExplanationForOneAttr_recurse(obj[prop], foundWords));
        }
      }
    }
    return res;
  }

  function _getHitExplanationForOneAttr(hit, foundWords, attr) {
    var base = hit._highlightResult || hit;
    if (attr.indexOf('.') === -1) {
      if (attr in base) {
        return _getHitExplanationForOneAttr_recurse(base[attr], foundWords);
      }
      return [];
    }
    var array = attr.split('.');
    var obj = base;
    for (var i = 0; i < array.length; ++i) {
      if (Object.prototype.toString.call(obj) === '[object Array]') {
        var res = [];
        for (var j = 0; j < obj.length; ++j) {
          res = res.concat(_getHitExplanationForOneAttr(obj[j], foundWords, array.slice(i).join('.')));
        }
        return res;
      }
      if (array[i] in obj) {
        obj = obj[array[i]];
      } else {
        return [];
      }
    }
    return _getHitExplanationForOneAttr_recurse(obj, foundWords);
  }

  var res = {};
  var foundWords = {};
  var title = _getHitExplanationForOneAttr(hit, foundWords, titleAttribute);
  res.title = (title.length > 0) ? title[0] : '';
  res.subtitles = [];

  if (typeof otherAttributes !== 'undefined') {
    for (var i = 0; i < otherAttributes.length; ++i) {
      var attr = _getHitExplanationForOneAttr(hit, foundWords, otherAttributes[i]);
      for (var j = 0; j < attr.length; ++j) {
        res.subtitles.push({ attr: otherAttributes[i], value: attr[j] });
      }
    }
  }
  return res;
}


AlgoliaSearch.prototype = {
  /*
   * Delete an index
   *
   * @param indexName the name of index to delete
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer that contains the task ID
   */
  deleteIndex: function(indexName, callback) {
    return this._jsonRequest({ method: 'DELETE',
              url: '/1/indexes/' + encodeURIComponent(indexName),
              callback: callback });
  },
  /**
   * Move an existing index.
   * @param srcIndexName the name of index to copy.
   * @param dstIndexName the new index name that will contains a copy of srcIndexName (destination will be overriten if it already exist).
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer that contains the task ID
   */
  moveIndex: function(srcIndexName, dstIndexName, callback) {
    var postObj = {operation: 'move', destination: dstIndexName};
    return this._jsonRequest({ method: 'POST',
              url: '/1/indexes/' + encodeURIComponent(srcIndexName) + '/operation',
              body: postObj,
              callback: callback });

  },
  /**
   * Copy an existing index.
   * @param srcIndexName the name of index to copy.
   * @param dstIndexName the new index name that will contains a copy of srcIndexName (destination will be overriten if it already exist).
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer that contains the task ID
   */
  copyIndex: function(srcIndexName, dstIndexName, callback) {
    var postObj = {operation: 'copy', destination: dstIndexName};
    return this._jsonRequest({ method: 'POST',
              url: '/1/indexes/' + encodeURIComponent(srcIndexName) + '/operation',
              body: postObj,
              callback: callback });
  },
  /**
   * Return last log entries.
   * @param offset Specify the first entry to retrieve (0-based, 0 is the most recent log entry).
   * @param length Specify the maximum number of entries to retrieve starting at offset. Maximum allowed value: 1000.
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer that contains the task ID
   */
  getLogs: function(callback, offset, length) {
    if (this._isUndefined(offset)) {
      offset = 0;
    }
    if (this._isUndefined(length)) {
      length = 10;
    }

    return this._jsonRequest({ method: 'GET',
              url: '/1/logs?offset=' + offset + '&length=' + length,
              callback: callback });
  },
  /*
   * List all existing indexes (paginated)
   *
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer with index list or error description if success is false.
   * @param page The page to retrieve, starting at 0.
   */
  listIndexes: function(callback, page) {
    var params = typeof page !== 'undefined' ? '?page=' + page : '';
    return this._jsonRequest({ method: 'GET',
              url: '/1/indexes' + params,
              callback: callback });
  },

  /*
   * Get the index object initialized
   *
   * @param indexName the name of index
   * @param callback the result callback with one argument (the Index instance)
   */
  initIndex: function(indexName) {
    return new this.Index(this, indexName);
  },
  /*
   * List all existing user keys with their associated ACLs
   *
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer with user keys list or error description if success is false.
   */
  listUserKeys: function(callback) {
    return this._jsonRequest({ method: 'GET',
              url: '/1/keys',
              callback: callback });
  },
  /*
   * Get ACL of a user key
   *
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer with user keys list or error description if success is false.
   */
  getUserKeyACL: function(key, callback) {
    return this._jsonRequest({ method: 'GET',
              url: '/1/keys/' + key,
              callback: callback });
  },
  /*
   * Delete an existing user key
   *
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer with user keys list or error description if success is false.
   */
  deleteUserKey: function(key, callback) {
    return this._jsonRequest({ method: 'DELETE',
              url: '/1/keys/' + key,
              callback: callback });
  },
  /*
   * Add an existing user key
   *
   * @param acls the list of ACL for this key. Defined by an array of strings that
   * can contains the following values:
   *   - search: allow to search (https and http)
   *   - addObject: allows to add/update an object in the index (https only)
   *   - deleteObject : allows to delete an existing object (https only)
   *   - deleteIndex : allows to delete index content (https only)
   *   - settings : allows to get index settings (https only)
   *   - editSettings : allows to change index settings (https only)
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer with user keys list or error description if success is false.
   */
  addUserKey: function(acls, callback) {
    return this.addUserKeyWithValidity(acls, 0, 0, 0, callback);
  },
  /*
   * Add an existing user key
   *
   * @param acls the list of ACL for this key. Defined by an array of strings that
   * can contains the following values:
   *   - search: allow to search (https and http)
   *   - addObject: allows to add/update an object in the index (https only)
   *   - deleteObject : allows to delete an existing object (https only)
   *   - deleteIndex : allows to delete index content (https only)
   *   - settings : allows to get index settings (https only)
   *   - editSettings : allows to change index settings (https only)
   * @param validity the number of seconds after which the key will be automatically removed (0 means no time limit for this key)
   * @param maxQueriesPerIPPerHour Specify the maximum number of API calls allowed from an IP address per hour.
   * @param maxHitsPerQuery Specify the maximum number of hits this API key can retrieve in one call.
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer with user keys list or error description if success is false.
   */
  addUserKeyWithValidity: function(acls, validity, maxQueriesPerIPPerHour, maxHitsPerQuery, callback) {
    var aclsObject = {};
    aclsObject.acl = acls;
    aclsObject.validity = validity;
    aclsObject.maxQueriesPerIPPerHour = maxQueriesPerIPPerHour;
    aclsObject.maxHitsPerQuery = maxHitsPerQuery;
    return this._jsonRequest({ method: 'POST',
              url: '/1/keys',
              body: aclsObject,
              callback: callback });
  },

  /**
   * Set the extra security tagFilters header
   * @param {string|array} tags The list of tags defining the current security filters
   */
  setSecurityTags: function(tags) {
    if (Object.prototype.toString.call(tags) === '[object Array]') {
      var strTags = [];
      for (var i = 0; i < tags.length; ++i) {
        if (Object.prototype.toString.call(tags[i]) === '[object Array]') {
          var oredTags = [];
          for (var j = 0; j < tags[i].length; ++j) {
            oredTags.push(tags[i][j]);
          }
          strTags.push('(' + oredTags.join(',') + ')');
        } else {
          strTags.push(tags[i]);
        }
      }
      tags = strTags.join(',');
    }
    this.tagFilters = tags;
  },

  /**
   * Set the extra user token header
   * @param {string} userToken The token identifying a uniq user (used to apply rate limits)
   */
  setUserToken: function(userToken) {
    this.userToken = userToken;
  },

  /*
   * Initialize a new batch of search queries
   */
  startQueriesBatch: function() {
    this.batch = [];
  },
  /*
   * Add a search query in the batch
   *
   * @param query the full text query
   * @param args (optional) if set, contains an object with query parameters:
   *  - attributes: an array of object attribute names to retrieve
   *     (if not set all attributes are retrieve)
   *  - attributesToHighlight: an array of object attribute names to highlight
   *     (if not set indexed attributes are highlighted)
   *  - minWordSizefor1Typo: the minimum number of characters to accept one typo.
   *     Defaults to 3.
   *  - minWordSizefor2Typos: the minimum number of characters to accept two typos.
   *     Defaults to 7.
   *  - getRankingInfo: if set, the result hits will contain ranking information in
   *     _rankingInfo attribute
   *  - page: (pagination parameter) page to retrieve (zero base). Defaults to 0.
   *  - hitsPerPage: (pagination parameter) number of hits per page. Defaults to 10.
   */
  addQueryInBatch: function(indexName, query, args) {
    var params = 'query=' + encodeURIComponent(query);
    if (!this._isUndefined(args) && args !== null) {
      params = this._getSearchParams(args, params);
    }
    this.batch.push({ indexName: indexName, params: params });
  },
  /*
   * Clear all queries in cache
   */
  clearCache: function() {
    this.cache = {};
  },
  /*
   * Launch the batch of queries using XMLHttpRequest.
   * (Optimized for browser using a POST query to minimize number of OPTIONS queries)
   *
   * @param callback the function that will receive results
   * @param delay (optional) if set, wait for this delay (in ms) and only send the batch if there was no other in the meantime.
   */
  sendQueriesBatch: function(callback, delay) {
    var as = this;
    var params = {requests: []};
    for (var i = 0; i < as.batch.length; ++i) {
      params.requests.push(as.batch[i]);
    }
    window.clearTimeout(as.onDelayTrigger);
    if (!this._isUndefined(delay) && delay !== null && delay > 0) {
      var onDelayTrigger = window.setTimeout( function() {
        as._sendQueriesBatch(params, callback);
      }, delay);
      as.onDelayTrigger = onDelayTrigger;
    } else {
      return this._sendQueriesBatch(params, callback);
    }
  },

   /**
   * Set the number of milliseconds a request can take before automatically being terminated.
   *
   * @param {Number} milliseconds
   */
  setRequestTimeout: function(milliseconds)
  {
    if (milliseconds) {
      this.requestTimeoutInMs = parseInt(milliseconds, 10);
    }
  },

  /*
   * Index class constructor.
   * You should not use this method directly but use initIndex() function
   */
  Index: function(algoliasearch, indexName) {
    this.indexName = indexName;
    this.as = algoliasearch;
    this.typeAheadArgs = null;
    this.typeAheadValueOption = null;

    // make sure every index instance has it's own cache
    this.cache = {};
  },
   /**
   * Add an extra field to the HTTP request
   *
   * @param key the header field name
   * @param value the header field value
   */
  setExtraHeader: function(key, value) {
    this.extraHeaders.push({ key: key, value: value});
  },

  _sendQueriesBatch: function(params, callback) {
     if (this.jsonp === null) {
      var self = this;
      return this._jsonRequest({ cache: this.cache,
        method: 'POST',
        url: '/1/indexes/*/queries',
        body: params,
        callback: function(success, content) {
          if (!success) {
            // retry first with JSONP
            self.jsonp = true;
            self._sendQueriesBatch(params, callback);
          } else {
            self.jsonp = false;
            callback && callback(success, content);
          }
        }
      });
    } else if (this.jsonp) {
      var jsonpParams = '';
      for (var i = 0; i < params.requests.length; ++i) {
        var q = '/1/indexes/' + encodeURIComponent(params.requests[i].indexName) + '?' + params.requests[i].params;
        jsonpParams += i + '=' + encodeURIComponent(q) + '&';
      }
      var pObj = {params: jsonpParams};
      return this._jsonRequest({ cache: this.cache,
                   method: 'GET',
                   url: '/1/indexes/*',
                   body: pObj,
                   callback: callback });
    } else {
      return this._jsonRequest({ cache: this.cache,
                   method: 'POST',
                   url: '/1/indexes/*/queries',
                   body: params,
                      callback: callback});
    }
  },
  /*
   * Wrapper that try all hosts to maximize the quality of service
   */
  _jsonRequest: function(opts) {
    var self = this;
    var callback = opts.callback;
    var cache = null;
    var cacheID = opts.url;
    var deferred = null;
    if (this.options.jQuery) {
      deferred = this.options.jQuery.$.Deferred();
      deferred.promise = deferred.promise(); // promise is a property in angular
    } else if (this.options.angular) {
      deferred = this.options.angular.$q.defer();
    }

    if (!this._isUndefined(opts.body)) {
      cacheID = opts.url + '_body_' + JSON.stringify(opts.body);
    }
    if (!this._isUndefined(opts.cache)) {
      cache = opts.cache;
      if (!this._isUndefined(cache[cacheID])) {
        if (!this._isUndefined(callback) && callback) {
          setTimeout(function () { callback(true, cache[cacheID]); }, 1);
        }
        deferred && deferred.resolve(cache[cacheID]);
        return deferred && deferred.promise;
      }
    }

    opts.successiveRetryCount = 0;
    var impl = function() {

      if (opts.successiveRetryCount >= self.hosts.length) {
        var error = { message: 'Cannot connect the Algolia\'s Search API. Please send an email to support@algolia.com to report the issue.' };
        if (!self._isUndefined(callback) && callback) {
          opts.successiveRetryCount = 0;
          callback(false, error);
        }
        deferred && deferred.reject(error);
        return;
      }
      opts.callback = function(retry, success, body) {
        if (success && !self._isUndefined(opts.cache)) {
          cache[cacheID] = body;
        }
        if (!success && retry) {
          self.currentHostIndex = ++self.currentHostIndex % self.hosts.length;
          opts.successiveRetryCount += 1;
          impl();
        } else {
          opts.successiveRetryCount = 0;
          deferred && (success ? deferred.resolve(body) : deferred.reject(body));
          if (!self._isUndefined(callback) && callback) {
            callback(success, body);
          }
        }
      };
      opts.hostname = self.hosts[self.currentHostIndex];
      self._jsonRequestByHost(opts);
    };
    impl();

    return deferred && deferred.promise;
  },

  _jsonRequestByHost: function(opts) {
    var self = this;
    var url = opts.hostname + opts.url;

    if (this.jsonp) {
      this._makeJsonpRequestByHost(url, opts);
    } else if (this.options.jQuery) {
      this._makejQueryRequestByHost(url, opts);
    } else if (this.options.angular) {
      this._makeAngularRequestByHost(url, opts);
    } else {
      this._makeXmlHttpRequestByHost(url, opts);
    }
  },

  /**
   * Make a $http
   *
   * @param url request url (includes endpoint and path)
   * @param opts all request opts
   */
  _makeAngularRequestByHost: function(url, opts) {
    var self = this;
    var body = null;

    if (!this._isUndefined(opts.body)) {
      body = JSON.stringify(opts.body);
    }

    url += ((url.indexOf('?') === -1) ? '?' : '&') + 'X-Algolia-API-Key=' + this.apiKey;
    url += '&X-Algolia-Application-Id=' + this.applicationID;
    if (this.userToken) {
      url += '&X-Algolia-UserToken=' + encodeURIComponent(this.userToken);
    }
    if (this.tagFilters) {
      url += '&X-Algolia-TagFilters=' + encodeURIComponent(this.tagFilters);
    }
    url += '&X-Algolia-Agent=' + encodeURIComponent(this._ua);
    for (var i = 0; i < this.extraHeaders.length; ++i) {
      url += '&' + this.extraHeaders[i].key + '=' + this.extraHeaders[i].value;
    }
    this.options.angular.$http({
      url: url,
      method: opts.method,
      data: body,
      cache: false,
      timeout: (this.requestTimeoutInMs * (opts.successiveRetryCount + 1))
    }).then(function(response) {
      opts.callback(false, true, response.data);
    }, function(response) {
      if (response.status === 0) {
        // xhr.timeout is not handled by Angular.js right now
        // let's retry
        opts.callback(true, false, response.data);
      } else if (response.status == 400 || response.status === 403 || response.status === 404) {
        opts.callback(false, false, response.data);
      } else {
        opts.callback(true, false, response.data);
      }
    });
  },

  /**
   * Make a $.ajax
   *
   * @param url request url (includes endpoint and path)
   * @param opts all request opts
   */
  _makejQueryRequestByHost: function(url, opts) {
    var self = this;
    var body = null;

    if (!this._isUndefined(opts.body)) {
      body = JSON.stringify(opts.body);
    }

    url += ((url.indexOf('?') === -1) ? '?' : '&') + 'X-Algolia-API-Key=' + this.apiKey;
    url += '&X-Algolia-Application-Id=' + this.applicationID;
    if (this.userToken) {
      url += '&X-Algolia-UserToken=' + encodeURIComponent(this.userToken);
    }
    if (this.tagFilters) {
      url += '&X-Algolia-TagFilters=' + encodeURIComponent(this.tagFilters);
    }
    url += '&X-Algolia-Agent=' + encodeURIComponent(this._ua);
    for (var i = 0; i < this.extraHeaders.length; ++i) {
      url += '&' + this.extraHeaders[i].key + '=' + this.extraHeaders[i].value;
    }
    this.options.jQuery.$.ajax(url, {
      type: opts.method,
      timeout: (this.requestTimeoutInMs * (opts.successiveRetryCount + 1)),
      dataType: 'json',
      data: body,
      error: function(xhr, textStatus, error) {
        if (textStatus === 'timeout') {
          opts.callback(true, false, { 'message': 'Timeout - Could not connect to endpoint ' + url } );
        } else if (xhr.status === 400 || xhr.status === 403 || xhr.status === 404) {
          opts.callback(false, false, xhr.responseJSON );
        } else {
          opts.callback(true, false, { 'message': error } );
        }
      },
      success: function(data, textStatus, xhr) {
        opts.callback(false, true, data);
      }
    });
  },

  /**
   * Make a JSONP request
   *
   * @param url request url (includes endpoint and path)
   * @param opts all request options
   */
  _makeJsonpRequestByHost: function(url, opts) {
    if (opts.method !== 'GET') {
      opts.callback(true, false, { 'message': 'Method ' + opts.method + ' ' + url + ' is not supported by JSONP.' });
      return;
    }

    var cbCalled = false;
    var timedOut = false;

    AlgoliaSearch.JSONPCounter += 1;
    var head = document.getElementsByTagName('head')[0];
    var script = document.createElement('script');
    var cb = 'algoliaJSONP_' + AlgoliaSearch.JSONPCounter;
    var done = false;
    var ontimeout;
    var success;
    var clean;

    window[cb] = function(data) {
      try { delete window[cb]; } catch (e) { window[cb] = undefined; }

      if (timedOut) {
        return;
      }

      var status =
        data && data.message && data.status ||
        data && 200;

      var ok = status === 200;
      var retry = !ok && status !== 400 && status !== 403 && status !== 404;
      cbCalled = true;
      opts.callback(retry, ok, data);
    };

    script.type = 'text/javascript';
    url += '?callback=' + cb + '&X-Algolia-Application-Id=' + this.applicationID + '&X-Algolia-API-Key=' + this.apiKey;

    if (this.tagFilters) {
      url += '&X-Algolia-TagFilters=' + encodeURIComponent(this.tagFilters);
    }

    if (this.userToken) {
      url += '&X-Algolia-UserToken=' + encodeURIComponent(this.userToken);
    }

    url += '&X-Algolia-Agent=' + encodeURIComponent(this._ua);

    for (var i = 0; i < this.extraHeaders.length; ++i) {
      url += '&' + this.extraHeaders[i].key + '=' + this.extraHeaders[i].value;
    }

    if (opts.body && opts.body.params) {
      url += '&' + opts.body.params;
    }

    ontimeout = setTimeout(function() {
      timedOut = true;
      clean();

      opts.callback(true, false, { 'message': 'Timeout - Failed to load JSONP script.' });
    }, this.requestTimeoutInMs * (opts.successiveRetryCount + 1));

    success = function() {
      if (done || timedOut) {
        return;
      }

      done = true;
      clean();

      // script loaded but did not call the fn => script loading error
      if (!cbCalled) {
        opts.callback(true, false, { 'message': 'Failed to load JSONP script.' });
      }
    };

    clean = function() {
      clearTimeout(ontimeout);
      script.onload = null;
      script.onreadystatechange = null;
      script.onerror = null;
      head.removeChild(script);

      try {
        delete window[cb];
        delete window[cb + '_loaded'];
      } catch (e) {
        window[cb] = null;
        window[cb + '_loaded'] = null;
      }
    };

    // script onreadystatechange needed only for
    // <= IE8
    // https://github.com/angular/angular.js/issues/4523
    script.onreadystatechange = function() {
      if (this.readyState === 'loaded' || this.readyState === 'complete') {
        success();
      }
    };

    script.onload = function() {
      success();
    };

    script.onerror = function() {
      if (done || timedOut) {
        return;
      }

      clean();
      opts.callback(true, false, { 'message': 'Failed to load JSONP script.' });
    };

    script.async = true;
    script.defer = true;
    script.src = url;

    head.appendChild(script);
  },

  /**
   * Make a XmlHttpRequest
   *
   * @param url request url (includes endpoint and path)
   * @param opts all request opts
   */
  _makeXmlHttpRequestByHost: function(url, opts) {
    // no cors or XDomainRequest, no request
    if (!this._support.cors && !this._support.hasXDomainRequest) {
      // very old browser, not supported
      opts.callback(false, false, { 'message': 'CORS not supported' });
      return;
    }

    var body = null;
    var request = this._support.cors ? new XMLHttpRequest() : new XDomainRequest();
    var ontimeout;
    var self = this;
    var timedOut;
    var timeoutListener;

    if (!this._isUndefined(opts.body)) {
      body = JSON.stringify(opts.body);
    }

    url += (url.indexOf('?') === -1 ? '?' : '&') + 'X-Algolia-API-Key=' + this.apiKey;
    url += '&X-Algolia-Application-Id=' + this.applicationID;

    if (this.userToken) {
      url += '&X-Algolia-UserToken=' + encodeURIComponent(this.userToken);
    }

    if (this.tagFilters) {
      url += '&X-Algolia-TagFilters=' + encodeURIComponent(this.tagFilters);
    }

    url += '&X-Algolia-Agent=' + encodeURIComponent(this._ua);

    for (var i = 0; i < this.extraHeaders.length; ++i) {
      url += '&' + this.extraHeaders[i].key + '=' + this.extraHeaders[i].value;
    }

    timeoutListener = function() {
      if (!self._support.timeout) {
        timedOut = true;
        request.abort();
      }

      opts.callback(true, false, { 'message': 'Timeout - Could not connect to endpoint ' + url } );
    };

    // do not rely on default XHR async flag, as some analytics code like hotjar
    // breaks it and set it to false by default
    if (request instanceof XMLHttpRequest) {
      request.open(opts.method, url, true);
    } else {
      request.open(opts.method, url);
    }

    if (this._support.cors && body !== null && opts.method !== 'GET') {
      request.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    }

    // event object not received in IE8, at least
    // but we do not use it, still important to note
    request.onload = function(/*event*/) {
      // When browser does not supports request.timeout, we can
      // have both a load and timeout event
      if (timedOut) {
        return;
      }

      if (!self._support.timeout) {
        clearTimeout(ontimeout);
      }

      var response = null;

      try {
        response = JSON.parse(request.responseText);
      } catch(e) {}

      var status =
        // XHR provides a `status` property
        request.status ||

        // XDR does not have a `status` property,
        // we rely on our own API response `status`, only
        // provided when an error occurs, so we expect a .message
        response && response.message && response.status ||

        // XDR default to success when no response.status
        response && 200;

      var success = status === 200 || status === 201;
      var retry = !success && status !== 400 && status !== 403 && status !== 404;

      opts.callback(retry, success, response);
    };

    // we set an empty onprogress listener
    // so that XDomainRequest on IE9 is not aborted
    // refs:
    //  - https://github.com/algolia/algoliasearch-client-js/issues/76
    //  - https://social.msdn.microsoft.com/Forums/ie/en-US/30ef3add-767c-4436-b8a9-f1ca19b4812e/ie9-rtm-xdomainrequest-issued-requests-may-abort-if-all-event-handlers-not-specified?forum=iewebdevelopment
    request.onprogress = function noop() {};

    if (this._support.timeout) {
      // .timeout supported by both XHR and XDR,
      // we do receive timeout event, tested
      request.timeout = this.requestTimeoutInMs * (opts.successiveRetryCount + 1);

      request.ontimeout = timeoutListener;
    } else {
      ontimeout = setTimeout(timeoutListener, this.requestTimeoutInMs * (opts.successiveRetryCount + 1));
    }

    request.onerror = function(event) {
      if (timedOut) {
        return;
      }

      if (!self._support.timeout) {
        clearTimeout(ontimeout);
      }

      // error event is trigerred both with XDR/XHR on:
      //   - DNS error
      //   - unallowed cross domain request
      opts.callback(true, false, { 'message': 'Could not connect to host', 'error': event } );
    };

    request.send(body);
  },

   /*
   * Transform search param object in query string
   */
  _getSearchParams: function(args, params) {
    if (this._isUndefined(args) || args === null) {
      return params;
    }
    for (var key in args) {
      if (key !== null && args.hasOwnProperty(key)) {
        params += (params.length === 0) ? '?' : '&';
        params += key + '=' + encodeURIComponent(Object.prototype.toString.call(args[key]) === '[object Array]' ? JSON.stringify(args[key]) : args[key]);
      }
    }
    return params;
  },
  _isUndefined: function(obj) {
    return obj === void 0;
  },

  _support: {
    hasXMLHttpRequest: 'XMLHttpRequest' in window,
    hasXDomainRequest: 'XDomainRequest' in window,
    cors: 'withCredentials' in new XMLHttpRequest(),
    timeout: 'timeout' in new XMLHttpRequest()
  }
};

/*
 * Contains all the functions related to one index
 * You should use AlgoliaSearch.initIndex(indexName) to retrieve this object
 */
AlgoliaSearch.prototype.Index.prototype = {
  /*
   * Clear all queries in cache
   */
  clearCache: function() {
    this.cache = {};
  },
  /*
   * Add an object in this index
   *
   * @param content contains the javascript object to add inside the index
   * @param callback (optional) the result callback with two arguments:
   *  success: boolean set to true if the request was successfull
   *  content: the server answer that contains 3 elements: createAt, taskId and objectID
   * @param objectID (optional) an objectID you want to attribute to this object
   * (if the attribute already exist the old object will be overwrite)
   */
  addObject: function(content, callback, objectID) {
    var indexObj = this;
    if (this.as._isUndefined(objectID)) {
      return this.as._jsonRequest({ method: 'POST',
                   url: '/1/indexes/' + encodeURIComponent(indexObj.indexName),
                   body: content,
                   callback: callback });
    } else {
      return this.as._jsonRequest({ method: 'PUT',
                   url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/' + encodeURIComponent(objectID),
                   body: content,
                   callback: callback });
    }

  },
  /*
   * Add several objects
   *
   * @param objects contains an array of objects to add
   * @param callback (optional) the result callback with two arguments:
   *  success: boolean set to true if the request was successfull
   *  content: the server answer that updateAt and taskID
   */
  addObjects: function(objects, callback) {
    var indexObj = this;
    var postObj = {requests:[]};
    for (var i = 0; i < objects.length; ++i) {
      var request = { action: 'addObject',
              body: objects[i] };
      postObj.requests.push(request);
    }
    return this.as._jsonRequest({ method: 'POST',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/batch',
                 body: postObj,
                 callback: callback });
  },
  /*
   * Get an object from this index
   *
   * @param objectID the unique identifier of the object to retrieve
   * @param callback (optional) the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the object to retrieve or the error message if a failure occured
   * @param attributes (optional) if set, contains the array of attribute names to retrieve
   */
  getObject: function(objectID, callback, attributes) {
    if (Object.prototype.toString.call(callback) === '[object Array]' && !attributes) {
      attributes = callback;
      callback = null;
    }
    var indexObj = this;
    var params = '';
    if (!this.as._isUndefined(attributes)) {
      params = '?attributes=';
      for (var i = 0; i < attributes.length; ++i) {
        if (i !== 0) {
          params += ',';
        }
        params += attributes[i];
      }
    }

    return this.as._jsonRequest({ method: 'GET',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/' + encodeURIComponent(objectID) + params,
                 callback: callback });
  },

  /*
   * Update partially an object (only update attributes passed in argument)
   *
   * @param partialObject contains the javascript attributes to override, the
   *  object must contains an objectID attribute
   * @param callback (optional) the result callback with two arguments:
   *  success: boolean set to true if the request was successfull
   *  content: the server answer that contains 3 elements: createAt, taskId and objectID
   */
  partialUpdateObject: function(partialObject, callback) {
    var indexObj = this;
    return this.as._jsonRequest({ method: 'POST',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/' + encodeURIComponent(partialObject.objectID) + '/partial',
                 body: partialObject,
                 callback:  callback });
  },
  /*
   * Partially Override the content of several objects
   *
   * @param objects contains an array of objects to update (each object must contains a objectID attribute)
   * @param callback (optional) the result callback with two arguments:
   *  success: boolean set to true if the request was successfull
   *  content: the server answer that updateAt and taskID
   */
  partialUpdateObjects: function(objects, callback) {
    var indexObj = this;
    var postObj = {requests:[]};
    for (var i = 0; i < objects.length; ++i) {
      var request = { action: 'partialUpdateObject',
              objectID: objects[i].objectID,
              body: objects[i] };
      postObj.requests.push(request);
    }
    return this.as._jsonRequest({ method: 'POST',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/batch',
                 body: postObj,
                 callback: callback });
  },
  /*
   * Override the content of object
   *
   * @param object contains the javascript object to save, the object must contains an objectID attribute
   * @param callback (optional) the result callback with two arguments:
   *  success: boolean set to true if the request was successfull
   *  content: the server answer that updateAt and taskID
   */
  saveObject: function(object, callback) {
    var indexObj = this;
    return this.as._jsonRequest({ method: 'PUT',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/' + encodeURIComponent(object.objectID),
                 body: object,
                 callback: callback });
  },
  /*
   * Override the content of several objects
   *
   * @param objects contains an array of objects to update (each object must contains a objectID attribute)
   * @param callback (optional) the result callback with two arguments:
   *  success: boolean set to true if the request was successfull
   *  content: the server answer that updateAt and taskID
   */
  saveObjects: function(objects, callback) {
    var indexObj = this;
    var postObj = {requests:[]};
    for (var i = 0; i < objects.length; ++i) {
      var request = { action: 'updateObject',
              objectID: objects[i].objectID,
              body: objects[i] };
      postObj.requests.push(request);
    }
    return this.as._jsonRequest({ method: 'POST',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/batch',
                 body: postObj,
                 callback: callback });
  },
  /*
   * Delete an object from the index
   *
   * @param objectID the unique identifier of object to delete
   * @param callback (optional) the result callback with two arguments:
   *  success: boolean set to true if the request was successfull
   *  content: the server answer that contains 3 elements: createAt, taskId and objectID
   */
  deleteObject: function(objectID, callback) {
    if (objectID === null || objectID.length === 0) {
      callback(false, { message: 'empty objectID'});
      return;
    }
    var indexObj = this;
    return this.as._jsonRequest({ method: 'DELETE',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/' + encodeURIComponent(objectID),
                 callback: callback });
  },
  /*
   * Search inside the index using XMLHttpRequest request (Using a POST query to
   * minimize number of OPTIONS queries: Cross-Origin Resource Sharing).
   *
   * @param query the full text query
   * @param callback the result callback with two arguments:
   *  success: boolean set to true if the request was successfull. If false, the content contains the error.
   *  content: the server answer that contains the list of results.
   * @param args (optional) if set, contains an object with query parameters:
   * - page: (integer) Pagination parameter used to select the page to retrieve.
   *                   Page is zero-based and defaults to 0. Thus, to retrieve the 10th page you need to set page=9
   * - hitsPerPage: (integer) Pagination parameter used to select the number of hits per page. Defaults to 20.
   * - attributesToRetrieve: a string that contains the list of object attributes you want to retrieve (let you minimize the answer size).
   *   Attributes are separated with a comma (for example "name,address").
   *   You can also use an array (for example ["name","address"]).
   *   By default, all attributes are retrieved. You can also use '*' to retrieve all values when an attributesToRetrieve setting is specified for your index.
   * - attributesToHighlight: a string that contains the list of attributes you want to highlight according to the query.
   *   Attributes are separated by a comma. You can also use an array (for example ["name","address"]).
   *   If an attribute has no match for the query, the raw value is returned. By default all indexed text attributes are highlighted.
   *   You can use `*` if you want to highlight all textual attributes. Numerical attributes are not highlighted.
   *   A matchLevel is returned for each highlighted attribute and can contain:
   *      - full: if all the query terms were found in the attribute,
   *      - partial: if only some of the query terms were found,
   *      - none: if none of the query terms were found.
   * - attributesToSnippet: a string that contains the list of attributes to snippet alongside the number of words to return (syntax is `attributeName:nbWords`).
   *    Attributes are separated by a comma (Example: attributesToSnippet=name:10,content:10).
   *    You can also use an array (Example: attributesToSnippet: ['name:10','content:10']). By default no snippet is computed.
   * - minWordSizefor1Typo: the minimum number of characters in a query word to accept one typo in this word. Defaults to 3.
   * - minWordSizefor2Typos: the minimum number of characters in a query word to accept two typos in this word. Defaults to 7.
   * - getRankingInfo: if set to 1, the result hits will contain ranking information in _rankingInfo attribute.
   * - aroundLatLng: search for entries around a given latitude/longitude (specified as two floats separated by a comma).
   *   For example aroundLatLng=47.316669,5.016670).
   *   You can specify the maximum distance in meters with the aroundRadius parameter (in meters) and the precision for ranking with aroundPrecision
   *   (for example if you set aroundPrecision=100, two objects that are distant of less than 100m will be considered as identical for "geo" ranking parameter).
   *   At indexing, you should specify geoloc of an object with the _geoloc attribute (in the form {"_geoloc":{"lat":48.853409, "lng":2.348800}})
   * - insideBoundingBox: search entries inside a given area defined by the two extreme points of a rectangle (defined by 4 floats: p1Lat,p1Lng,p2Lat,p2Lng).
   *   For example insideBoundingBox=47.3165,4.9665,47.3424,5.0201).
   *   At indexing, you should specify geoloc of an object with the _geoloc attribute (in the form {"_geoloc":{"lat":48.853409, "lng":2.348800}})
   * - numericFilters: a string that contains the list of numeric filters you want to apply separated by a comma.
   *   The syntax of one filter is `attributeName` followed by `operand` followed by `value`. Supported operands are `<`, `<=`, `=`, `>` and `>=`.
   *   You can have multiple conditions on one attribute like for example numericFilters=price>100,price<1000.
   *   You can also use an array (for example numericFilters: ["price>100","price<1000"]).
   * - tagFilters: filter the query by a set of tags. You can AND tags by separating them by commas.
   *   To OR tags, you must add parentheses. For example, tags=tag1,(tag2,tag3) means tag1 AND (tag2 OR tag3).
   *   You can also use an array, for example tagFilters: ["tag1",["tag2","tag3"]] means tag1 AND (tag2 OR tag3).
   *   At indexing, tags should be added in the _tags** attribute of objects (for example {"_tags":["tag1","tag2"]}).
   * - facetFilters: filter the query by a list of facets.
   *   Facets are separated by commas and each facet is encoded as `attributeName:value`.
   *   For example: `facetFilters=category:Book,author:John%20Doe`.
   *   You can also use an array (for example `["category:Book","author:John%20Doe"]`).
   * - facets: List of object attributes that you want to use for faceting.
   *   Comma separated list: `"category,author"` or array `['category','author']`
   *   Only attributes that have been added in **attributesForFaceting** index setting can be used in this parameter.
   *   You can also use `*` to perform faceting on all attributes specified in **attributesForFaceting**.
   * - queryType: select how the query words are interpreted, it can be one of the following value:
   *    - prefixAll: all query words are interpreted as prefixes,
   *    - prefixLast: only the last word is interpreted as a prefix (default behavior),
   *    - prefixNone: no query word is interpreted as a prefix. This option is not recommended.
   * - optionalWords: a string that contains the list of words that should be considered as optional when found in the query.
   *   Comma separated and array are accepted.
   * - distinct: If set to 1, enable the distinct feature (disabled by default) if the attributeForDistinct index setting is set.
   *   This feature is similar to the SQL "distinct" keyword: when enabled in a query with the distinct=1 parameter,
   *   all hits containing a duplicate value for the attributeForDistinct attribute are removed from results.
   *   For example, if the chosen attribute is show_name and several hits have the same value for show_name, then only the best
   *   one is kept and others are removed.
   * - restrictSearchableAttributes: List of attributes you want to use for textual search (must be a subset of the attributesToIndex index setting)
   * either comma separated or as an array
   * @param delay (optional) if set, wait for this delay (in ms) and only send the query if there was no other in the meantime.
   */
  search: function(query, callback, args, delay) {
    if (query === undefined || query === null) {
      query = '';
    }

    // no query = getAllObjects
    if (typeof query === 'function') {
      callback = query;
      query = '';
    }

    if (typeof callback === 'object' && (this.as._isUndefined(args) || !args)) {
      args = callback;
      callback = null;
    }

    var indexObj = this;
    var params = 'query=' + encodeURIComponent(query);
    if (!this.as._isUndefined(args) && args !== null) {
      params = this.as._getSearchParams(args, params);
    }
    window.clearTimeout(indexObj.onDelayTrigger);
    if (!this.as._isUndefined(delay) && delay !== null && delay > 0) {
      var onDelayTrigger = window.setTimeout( function() {
        indexObj._search(params, callback);
      }, delay);
      indexObj.onDelayTrigger = onDelayTrigger;
    } else {
      return this._search(params, callback);
    }
  },

  /*
   * Browse all index content
   *
   * @param page Pagination parameter used to select the page to retrieve.
   *             Page is zero-based and defaults to 0. Thus, to retrieve the 10th page you need to set page=9
   * @param hitsPerPage: Pagination parameter used to select the number of hits per page. Defaults to 1000.
   */
  browse: function(page, callback, hitsPerPage) {
    if (+callback > 0 && (this.as._isUndefined(hitsPerPage) || !hitsPerPage)) {
      hitsPerPage = callback;
      callback = null;
    }
    var indexObj = this;
    var params = '?page=' + page;
    if (!this.as._isUndefined(hitsPerPage)) {
      params += '&hitsPerPage=' + hitsPerPage;
    }
    return this.as._jsonRequest({ method: 'GET',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/browse' + params,
                 callback: callback });
  },

  /*
   * Get a Typeahead.js adapter
   * @param searchParams contains an object with query parameters (see search for details)
   */
  ttAdapter: function(params) {
    var self = this;
    return function(query, cb) {
      self.search(query, function(success, content) {
        if (success) {
          cb(content.hits);
        } else {
          cb(content && content.message);
        }
      }, params);
    };
  },

  /*
   * Wait the publication of a task on the server.
   * All server task are asynchronous and you can check with this method that the task is published.
   *
   * @param taskID the id of the task returned by server
   * @param callback the result callback with with two arguments:
   *  success: boolean set to true if the request was successfull
   *  content: the server answer that contains the list of results
   */
  waitTask: function(taskID, callback) {
    var indexObj = this;
    return this.as._jsonRequest({ method: 'GET',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/task/' + taskID,
                 callback: function(success, body) {
      if (success) {
        if (body.status === 'published') {
          callback(true, body);
        } else {
          setTimeout(function() { indexObj.waitTask(taskID, callback); }, 100);
        }
      } else {
        callback(false, body);
      }
    }});
  },

  /*
   * This function deletes the index content. Settings and index specific API keys are kept untouched.
   *
   * @param callback (optional) the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the settings object or the error message if a failure occured
   */
  clearIndex: function(callback) {
    var indexObj = this;
    return this.as._jsonRequest({ method: 'POST',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/clear',
                 callback: callback });
  },
  /*
   * Get settings of this index
   *
   * @param callback (optional) the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the settings object or the error message if a failure occured
   */
  getSettings: function(callback) {
    var indexObj = this;
    return this.as._jsonRequest({ method: 'GET',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/settings',
                 callback: callback });
  },

  /*
   * Set settings for this index
   *
   * @param settigns the settings object that can contains :
   * - minWordSizefor1Typo: (integer) the minimum number of characters to accept one typo (default = 3).
   * - minWordSizefor2Typos: (integer) the minimum number of characters to accept two typos (default = 7).
   * - hitsPerPage: (integer) the number of hits per page (default = 10).
   * - attributesToRetrieve: (array of strings) default list of attributes to retrieve in objects.
   *   If set to null, all attributes are retrieved.
   * - attributesToHighlight: (array of strings) default list of attributes to highlight.
   *   If set to null, all indexed attributes are highlighted.
   * - attributesToSnippet**: (array of strings) default list of attributes to snippet alongside the number of words to return (syntax is attributeName:nbWords).
   *   By default no snippet is computed. If set to null, no snippet is computed.
   * - attributesToIndex: (array of strings) the list of fields you want to index.
   *   If set to null, all textual and numerical attributes of your objects are indexed, but you should update it to get optimal results.
   *   This parameter has two important uses:
   *     - Limit the attributes to index: For example if you store a binary image in base64, you want to store it and be able to
   *       retrieve it but you don't want to search in the base64 string.
   *     - Control part of the ranking*: (see the ranking parameter for full explanation) Matches in attributes at the beginning of
   *       the list will be considered more important than matches in attributes further down the list.
   *       In one attribute, matching text at the beginning of the attribute will be considered more important than text after, you can disable
   *       this behavior if you add your attribute inside `unordered(AttributeName)`, for example attributesToIndex: ["title", "unordered(text)"].
   * - attributesForFaceting: (array of strings) The list of fields you want to use for faceting.
   *   All strings in the attribute selected for faceting are extracted and added as a facet. If set to null, no attribute is used for faceting.
   * - attributeForDistinct: (string) The attribute name used for the Distinct feature. This feature is similar to the SQL "distinct" keyword: when enabled
   *   in query with the distinct=1 parameter, all hits containing a duplicate value for this attribute are removed from results.
   *   For example, if the chosen attribute is show_name and several hits have the same value for show_name, then only the best one is kept and others are removed.
   * - ranking: (array of strings) controls the way results are sorted.
   *   We have six available criteria:
   *    - typo: sort according to number of typos,
   *    - geo: sort according to decreassing distance when performing a geo-location based search,
   *    - proximity: sort according to the proximity of query words in hits,
   *    - attribute: sort according to the order of attributes defined by attributesToIndex,
   *    - exact:
   *        - if the user query contains one word: sort objects having an attribute that is exactly the query word before others.
   *          For example if you search for the "V" TV show, you want to find it with the "V" query and avoid to have all popular TV
   *          show starting by the v letter before it.
   *        - if the user query contains multiple words: sort according to the number of words that matched exactly (and not as a prefix).
   *    - custom: sort according to a user defined formula set in **customRanking** attribute.
   *   The standard order is ["typo", "geo", "proximity", "attribute", "exact", "custom"]
   * - customRanking: (array of strings) lets you specify part of the ranking.
   *   The syntax of this condition is an array of strings containing attributes prefixed by asc (ascending order) or desc (descending order) operator.
   *   For example `"customRanking" => ["desc(population)", "asc(name)"]`
   * - queryType: Select how the query words are interpreted, it can be one of the following value:
   *   - prefixAll: all query words are interpreted as prefixes,
   *   - prefixLast: only the last word is interpreted as a prefix (default behavior),
   *   - prefixNone: no query word is interpreted as a prefix. This option is not recommended.
   * - highlightPreTag: (string) Specify the string that is inserted before the highlighted parts in the query result (default to "<em>").
   * - highlightPostTag: (string) Specify the string that is inserted after the highlighted parts in the query result (default to "</em>").
   * - optionalWords: (array of strings) Specify a list of words that should be considered as optional when found in the query.
   * @param callback (optional) the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer or the error message if a failure occured
   */
  setSettings: function(settings, callback) {
    var indexObj = this;
    return this.as._jsonRequest({ method: 'PUT',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/settings',
                 body: settings,
                 callback: callback });
  },
  /*
   * List all existing user keys associated to this index
   *
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer with user keys list or error description if success is false.
   */
  listUserKeys: function(callback) {
    var indexObj = this;
    return this.as._jsonRequest({ method: 'GET',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/keys',
                 callback: callback });
  },
  /*
   * Get ACL of a user key associated to this index
   *
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer with user keys list or error description if success is false.
   */
  getUserKeyACL: function(key, callback) {
    var indexObj = this;
    return this.as._jsonRequest({ method: 'GET',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/keys/' + key,
                 callback: callback });
  },
  /*
   * Delete an existing user key associated to this index
   *
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer with user keys list or error description if success is false.
   */
  deleteUserKey: function(key, callback) {
    var indexObj = this;
    return this.as._jsonRequest({ method: 'DELETE',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/keys/' + key,
                 callback: callback });
  },
  /*
   * Add an existing user key associated to this index
   *
   * @param acls the list of ACL for this key. Defined by an array of strings that
   * can contains the following values:
   *   - search: allow to search (https and http)
   *   - addObject: allows to add/update an object in the index (https only)
   *   - deleteObject : allows to delete an existing object (https only)
   *   - deleteIndex : allows to delete index content (https only)
   *   - settings : allows to get index settings (https only)
   *   - editSettings : allows to change index settings (https only)
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer with user keys list or error description if success is false.
   */
  addUserKey: function(acls, callback) {
    var indexObj = this;
    var aclsObject = {};
    aclsObject.acl = acls;
    return this.as._jsonRequest({ method: 'POST',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/keys',
                 body: aclsObject,
                 callback: callback });
  },
  /*
   * Add an existing user key associated to this index
   *
   * @param acls the list of ACL for this key. Defined by an array of strings that
   * can contains the following values:
   *   - search: allow to search (https and http)
   *   - addObject: allows to add/update an object in the index (https only)
   *   - deleteObject : allows to delete an existing object (https only)
   *   - deleteIndex : allows to delete index content (https only)
   *   - settings : allows to get index settings (https only)
   *   - editSettings : allows to change index settings (https only)
   * @param validity the number of seconds after which the key will be automatically removed (0 means no time limit for this key)
   * @param maxQueriesPerIPPerHour Specify the maximum number of API calls allowed from an IP address per hour.
   * @param maxHitsPerQuery Specify the maximum number of hits this API key can retrieve in one call.
   * @param callback the result callback with two arguments
   *  success: boolean set to true if the request was successfull
   *  content: the server answer with user keys list or error description if success is false.
   */
  addUserKeyWithValidity: function(acls, validity, maxQueriesPerIPPerHour, maxHitsPerQuery, callback) {
    var indexObj = this;
    var aclsObject = {};
    aclsObject.acl = acls;
    aclsObject.validity = validity;
    aclsObject.maxQueriesPerIPPerHour = maxQueriesPerIPPerHour;
    aclsObject.maxHitsPerQuery = maxHitsPerQuery;
    return this.as._jsonRequest({ method: 'POST',
                 url: '/1/indexes/' + encodeURIComponent(indexObj.indexName) + '/keys',
                 body: aclsObject,
                 callback: callback });
  },
  ///
  /// Internal methods only after this line
  ///
  _search: function(params, callback) {
    var pObj = {params: params};
    if (this.as.jsonp === null) {
      var self = this;
      return this.as._jsonRequest({ cache: this.cache,
        method: 'POST',
        url: '/1/indexes/' + encodeURIComponent(this.indexName) + '/query',
        body: pObj,
        callback: function(success, content) {
          var status = content && content.status;
          if (success || status && Math.floor(status / 100) === 4 || Math.floor(status / 100) === 1) {
            self.as.jsonp = false;
            callback && callback(success, content);
          } else {
            self.as.jsonp = true;
            self._search(params, callback);
          }
        }
      });
    } else if (this.as.jsonp) {
      return this.as._jsonRequest({ cache: this.cache,
                   method: 'GET',
                   url: '/1/indexes/' + encodeURIComponent(this.indexName),
                   body: pObj,
                   callback: callback });
    } else {
      return this.as._jsonRequest({ cache: this.cache,
                   method: 'POST',
                   url: '/1/indexes/' + encodeURIComponent(this.indexName) + '/query',
                   body: pObj,
                   callback: callback});
    }
  },

  // internal attributes
  as: null,
  indexName: null,
  typeAheadArgs: null,
  typeAheadValueOption: null
};

/*
 * Copyright (c) 2014 Algolia
 * http://www.algolia.com/
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

(function($) {
  var extend = function(out) {
    out = out || {};
    for (var i = 1; i < arguments.length; i++) {
      if (!arguments[i]) {
        continue;
      }
      for (var key in arguments[i]) {
        if (arguments[i].hasOwnProperty(key)) {
          out[key] = arguments[i][key];
        }
      }
    }
    return out;
  };
  
  /**
   * Algolia Search Helper providing faceting and disjunctive faceting
   * @param {AlgoliaSearch} client an AlgoliaSearch client
   * @param {string} index the index name to query
   * @param {hash} options an associative array defining the hitsPerPage, list of facets, the list of disjunctive facets and the default facet filters
   */
  window.AlgoliaSearchHelper = function(client, index, options) {
    /// Default options
    var defaults = {
      facets: [],            // list of facets to compute
      disjunctiveFacets: [], // list of disjunctive facets to compute
      hitsPerPage: 20,       // number of hits per page
      defaultFacetFilters: [] // the default list of facetFilters
    };

    this.init(client, index, extend({}, defaults, options));
  };

  AlgoliaSearchHelper.prototype = {
    /**
     * Initialize a new AlgoliaSearchHelper
     * @param  {AlgoliaSearch} client an AlgoliaSearch client
     * @param  {string} index the index name to query
     * @param  {hash} options an associative array defining the hitsPerPage, list of facets and list of disjunctive facets
     * @return {AlgoliaSearchHelper}
     */
    init: function(client, index, options) {
      this.client = client;
      this.index = index;
      this.options = options;
      this.page = 0;
      this.refinements = {};
      this.excludes = {};
      this.disjunctiveRefinements = {};
      this.extraQueries = [];
    },

    /**
     * Perform a query
     * @param  {string} q the user query
     * @param  {function} searchCallback the result callback called with two arguments:
     *  success: boolean set to true if the request was successfull
     *  content: the query answer with an extra 'disjunctiveFacets' attribute
     */
    search: function(q, searchCallback, searchParams) {
      this.q = q;
      this.searchCallback = searchCallback;
      this.searchParams = searchParams || {};
      this.page = this.page || 0;
      this.refinements = this.refinements || {};
      this.disjunctiveRefinements = this.disjunctiveRefinements || {};
      this._search();
    },
    
    /**
     * Remove all refinements (disjunctive + conjunctive)
     */
    clearRefinements: function() {
      this.disjunctiveRefinements = {};
      this.refinements = {};
    },

    /**
     * Ensure a facet refinement exists
     * @param  {string} facet the facet to refine
     * @param  {string} value the associated value
     */
    addDisjunctiveRefine: function(facet, value) {
      this.disjunctiveRefinements = this.disjunctiveRefinements || {};
      this.disjunctiveRefinements[facet] = this.disjunctiveRefinements[facet] || {};
      this.disjunctiveRefinements[facet][value] = true;
    },

    /**
     * Ensure a facet refinement does not exist
     * @param  {string} facet the facet to refine
     * @param  {string} value the associated value
     */
    removeDisjunctiveRefine: function(facet, value) {
      this.disjunctiveRefinements = this.disjunctiveRefinements || {};
      this.disjunctiveRefinements[facet] = this.disjunctiveRefinements[facet] || {};
      try {
        delete this.disjunctiveRefinements[facet][value];
      } catch (e) {
        this.disjunctiveRefinements[facet][value] = undefined; // IE compat
      }
    },

    /**
     * Ensure a facet refinement exists
     * @param  {string} facet the facet to refine
     * @param  {string} value the associated value
     */
    addRefine: function(facet, value) {
      var refinement = facet + ':' + value;
      this.refinements = this.refinements || {};
      this.refinements[refinement] = true;
    },

    /**
     * Ensure a facet refinement does not exist
     * @param  {string} facet the facet to refine
     * @param  {string} value the associated value
     */
    removeRefine: function(facet, value) {
      var refinement = facet + ':' + value;
      this.refinements = this.refinements || {};
      this.refinements[refinement] = false;
    },

    /**
     * Ensure a facet exclude exists
     * @param  {string} facet the facet to refine
     * @param  {string} value the associated value
     */
    addExclude: function(facet, value) {
      var refinement = facet + ':-' + value;
      this.excludes = this.excludes || {};
      this.excludes[refinement] = true;
    },

    /**
     * Ensure a facet exclude does not exist
     * @param  {string} facet the facet to refine
     * @param  {string} value the associated value
     */
    removeExclude: function(facet, value) {
      var refinement = facet + ':-' + value;
      this.excludes = this.excludes || {};
      this.excludes[refinement] = false;
    },

    /**
     * Toggle refinement state of an exclude
     * @param  {string} facet the facet to refine
     * @param  {string} value the associated value
     * @return {boolean} true if the facet has been found
     */
    toggleExclude: function(facet, value) {
      for (var i = 0; i < this.options.facets.length; ++i) {
        if (this.options.facets[i] == facet) {
          var refinement = facet + ':-' + value;
          this.excludes[refinement] = !this.excludes[refinement];
          this.page = 0;
          this._search();
          return true;
        }
      }
      return false;
    },

    /**
     * Toggle refinement state of a facet
     * @param  {string} facet the facet to refine
     * @param  {string} value the associated value
     * @return {boolean} true if the facet has been found
     */
    toggleRefine: function(facet, value) {
      for (var i = 0; i < this.options.facets.length; ++i) {
        if (this.options.facets[i] == facet) {
          var refinement = facet + ':' + value;
          this.refinements[refinement] = !this.refinements[refinement];
          this.page = 0;
          this._search();
          return true;
        }
      }
      this.disjunctiveRefinements[facet] = this.disjunctiveRefinements[facet] || {};
      for (var j = 0; j < this.options.disjunctiveFacets.length; ++j) {
        if (this.options.disjunctiveFacets[j] == facet) {
          this.disjunctiveRefinements[facet][value] = !this.disjunctiveRefinements[facet][value];
          this.page = 0;
          this._search();
          return true;
        }
      }
      return false;
    },

    /**
     * Check the refinement state of a facet
     * @param  {string}  facet the facet
     * @param  {string}  value the associated value
     * @return {boolean} true if refined
     */
    isRefined: function(facet, value) {
      var refinement = facet + ':' + value;
      if (this.refinements[refinement]) {
        return true;
      }
      if (this.disjunctiveRefinements[facet] && this.disjunctiveRefinements[facet][value]) {
        return true;
      }
      return false;
    },

    /**
     * Check the exclude state of a facet
     * @param  {string}  facet the facet
     * @param  {string}  value the associated value
     * @return {boolean} true if refined
     */
    isExcluded: function(facet, value) {
      var refinement = facet + ':-' + value;
      if (this.excludes[refinement]) {
        return true;
      }
      return false;
    },

    /**
     * Go to next page
     */
    nextPage: function() {
      this._gotoPage(this.page + 1);
    },

    /**
     * Go to previous page
     */
    previousPage: function() {
      if (this.page > 0) {
        this._gotoPage(this.page - 1);
      }
    },

    /**
     * Goto a page
     * @param  {integer} page The page number
     */
    gotoPage: function(page) {
        this._gotoPage(page);
    },

    /**
     * Configure the page but do not trigger a reload
     * @param  {integer} page The page number
     */
    setPage: function(page) {
      this.page = page;
    },

    /**
     * Configure the underlying index name
     * @param {string} name the index name
     */
    setIndex: function(name) {
      this.index = name;
    },

    /**
     * Get the underlying configured index name
     */
    getIndex: function() {
      return this.index;
    },

    /**
     * Clear the extra queries added to the underlying batch of queries
     */
    clearExtraQueries: function() {
      this.extraQueries = [];
    },

    /**
     * Add an extra query to the underlying batch of queries. Once you add queries
     * to the batch, the 2nd parameter of the searchCallback will be an object with a `results`
     * attribute listing all search results.
     */
    addExtraQuery: function(index, query, params) {
      this.extraQueries.push({ index: index, query: query, params: (params || {}) });
    },

    ///////////// PRIVATE

    /**
     * Goto a page
     * @param  {integer} page The page number
     */
    _gotoPage: function(page) {
      this.page = page;
      this._search();
    },

    /**
     * Perform the underlying queries
     */
    _search: function() {
      this.client.startQueriesBatch();
      this.client.addQueryInBatch(this.index, this.q, this._getHitsSearchParams());
      var disjunctiveFacets = [];
      var unusedDisjunctiveFacets = {};
      var i = 0;
      for (i = 0; i < this.options.disjunctiveFacets.length; ++i) {
        var facet = this.options.disjunctiveFacets[i];
        if (this._hasDisjunctiveRefinements(facet)) {
          disjunctiveFacets.push(facet);
        } else {
          unusedDisjunctiveFacets[facet] = true;
        }
      }
      for (i = 0; i < disjunctiveFacets.length; ++i) {
        this.client.addQueryInBatch(this.index, this.q, this._getDisjunctiveFacetSearchParams(disjunctiveFacets[i]));
      }
      for (i = 0; i < this.extraQueries.length; ++i) {
        this.client.addQueryInBatch(this.extraQueries[i].index, this.extraQueries[i].query, this.extraQueries[i].params);
      }
      var self = this;
      this.client.sendQueriesBatch(function(success, content) {
        if (!success) {
          self.searchCallback(false, content);
          return;
        }
        var aggregatedAnswer = content.results[0];
        aggregatedAnswer.disjunctiveFacets = aggregatedAnswer.disjunctiveFacets || {};
        aggregatedAnswer.facets_stats = aggregatedAnswer.facets_stats || {};
        // create disjunctive facets from facets (disjunctive facets without refinements)
        for (var facet in unusedDisjunctiveFacets) {
          if (aggregatedAnswer.facets[facet] && !aggregatedAnswer.disjunctiveFacets[facet]) {
            aggregatedAnswer.disjunctiveFacets[facet] = aggregatedAnswer.facets[facet];
            try {
              delete aggregatedAnswer.facets[facet];
            } catch (e) {
              aggregatedAnswer.facets[facet] = undefined; // IE compat
            }
          }
        }
        // aggregate the disjunctive facets
        for (i = 0; i < disjunctiveFacets.length; ++i) {
          for (var dfacet in content.results[i + 1].facets) {
            aggregatedAnswer.disjunctiveFacets[dfacet] = content.results[i + 1].facets[dfacet];
            if (self.disjunctiveRefinements[dfacet]) {
              for (var value in self.disjunctiveRefinements[dfacet]) {
                // add the disjunctive reginements if it is no more retrieved
                if (!aggregatedAnswer.disjunctiveFacets[dfacet][value] && self.disjunctiveRefinements[dfacet][value]) {
                  aggregatedAnswer.disjunctiveFacets[dfacet][value] = 0;
                }
              }
            }
          }
          // aggregate the disjunctive facets stats
          for (var stats in content.results[i + 1].facets_stats) {
            aggregatedAnswer.facets_stats[stats] = content.results[i + 1].facets_stats[stats];
          }
        }

        // Backward compatibility
        aggregatedAnswer.facetStats = aggregatedAnswer.facets_stats;

        // add the excludes
        for (var exclude in self.excludes) {
          if (self.excludes[exclude]) {
            var e = exclude.indexOf(':-');
            var facet = exclude.slice(0, e);
            var value = exclude.slice(e + 2);
            aggregatedAnswer.facets[facet] = aggregatedAnswer.facets[facet] || {};
            if (!aggregatedAnswer.facets[facet][value]) {
              aggregatedAnswer.facets[facet][value] = 0;
            }
          }
        }
        // call the actual callback
        if (self.extraQueries.length === 0) {
          self.searchCallback(true, aggregatedAnswer);
        } else {
          // append the extra queries
          var c = { results: [ aggregatedAnswer ] };
          for (i = 0; i < self.extraQueries.length; ++i) {
            c.results.push(content.results[1 + disjunctiveFacets.length + i]);
          }
          self.searchCallback(true, c);
        }
      });
    },

    /**
     * Build search parameters used to fetch hits
     * @return {hash}
     */
    _getHitsSearchParams: function() {
      var facets = [];
      var i = 0;
      for (i = 0; i < this.options.facets.length; ++i) {
        facets.push(this.options.facets[i]);
      }
      for (i = 0; i < this.options.disjunctiveFacets.length; ++i) {
        var facet = this.options.disjunctiveFacets[i];
        if (!this._hasDisjunctiveRefinements(facet)) {
          facets.push(facet);
        }
      }
      return extend({}, {
        hitsPerPage: this.options.hitsPerPage,
        page: this.page,
        facets: facets,
        facetFilters: this._getFacetFilters()
      }, this.searchParams);
    },

    /**
     * Build search parameters used to fetch a disjunctive facet
     * @param  {string} facet the associated facet name
     * @return {hash}
     */
    _getDisjunctiveFacetSearchParams: function(facet) {
      return extend({}, this.searchParams, {
        hitsPerPage: 1,
        page: 0,
        attributesToRetrieve: [],
        attributesToHighlight: [],
        attributesToSnippet: [],
        facets: facet,
        facetFilters: this._getFacetFilters(facet),
        analytics: false
      });
    },

    /**
     * Test if there are some disjunctive refinements on the facet
     */
    _hasDisjunctiveRefinements: function(facet) {
      for (var value in this.disjunctiveRefinements[facet]) {
        if (this.disjunctiveRefinements[facet][value]) {
          return true;
        }
      }
      return false;
    },

    /**
     * Build facetFilters parameter based on current refinements
     * @param  {string} facet if set, the current disjunctive facet
     * @return {hash}
     */
    _getFacetFilters: function(facet) {
      var facetFilters = [];
      if (this.options.defaultFacetFilters) {
        for (var i = 0; i < this.options.defaultFacetFilters.length; ++i) {
          facetFilters.push(this.options.defaultFacetFilters[i]);
        }
      }
      for (var refinement in this.refinements) {
        if (this.refinements[refinement]) {
          facetFilters.push(refinement);
        }
      }
      for (var refinement in this.excludes) {
        if (this.excludes[refinement]) {
          facetFilters.push(refinement);
        }
      }
      for (var disjunctiveRefinement in this.disjunctiveRefinements) {
        if (disjunctiveRefinement != facet) {
          var refinements = [];
          for (var value in this.disjunctiveRefinements[disjunctiveRefinement]) {
            if (this.disjunctiveRefinements[disjunctiveRefinement][value]) {
              refinements.push(disjunctiveRefinement + ':' + value);
            }
          }
          if (refinements.length > 0) {
            facetFilters.push(refinements);
          }
        }
      }
      return facetFilters;
    }
  };
})();

/*
 * Copyright (c) 2014 Algolia
 * http://www.algolia.com/
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

(function($) {
  
  /**
   * Algolia Places API
   * @param {string} Your application ID
   * @param {string} Your API Key
   */
  window.AlgoliaPlaces = function(applicationID, apiKey) {
     this.init(applicationID, apiKey);
  };

  AlgoliaPlaces.prototype = {
    /**
     * @param {string} Your application ID
     * @param {string} Your API Key
     */
    init: function(applicationID, apiKey) {
      this.client = new AlgoliaSearch(applicationID, apiKey, 'http', true, ['places-1.algolia.io', 'places-2.algolia.io', 'places-3.algolia.io']);
      this.cache = {};
    },

    /**
     * Perform a query
     * @param  {string} q the user query
     * @param  {function} searchCallback the result callback called with two arguments:
     *  success: boolean set to true if the request was successfull
     *  content: the query answer with an extra 'disjunctiveFacets' attribute
     * @param {hash} the list of search parameters
     */
    search: function(q, searchCallback, searchParams) {
      var indexObj = this;
      var params = 'query=' + encodeURIComponent(q);
      if (!this.client._isUndefined(searchParams) && searchParams != null) {
          params = this.client._getSearchParams(searchParams, params);
      }
      var pObj = {params: params, apiKey: this.client.apiKey, appID: this.client.applicationID};
      this.client._jsonRequest({ cache: this.cache,
                                 method: 'POST',
                                 url: '/1/places/query',
                                 body: pObj,
                                 callback: searchCallback,
                                 removeCustomHTTPHeaders: true });
    }
  };
})();

/*
    json2.js
    2014-02-04

    Public Domain.

    NO WARRANTY EXPRESSED OR IMPLIED. USE AT YOUR OWN RISK.

    See http://www.JSON.org/js.html


    This code should be minified before deployment.
    See http://javascript.crockford.com/jsmin.html

    USE YOUR OWN COPY. IT IS EXTREMELY UNWISE TO LOAD CODE FROM SERVERS YOU DO
    NOT CONTROL.


    This file creates a global JSON object containing two methods: stringify
    and parse.

        JSON.stringify(value, replacer, space)
            value       any JavaScript value, usually an object or array.

            replacer    an optional parameter that determines how object
                        values are stringified for objects. It can be a
                        function or an array of strings.

            space       an optional parameter that specifies the indentation
                        of nested structures. If it is omitted, the text will
                        be packed without extra whitespace. If it is a number,
                        it will specify the number of spaces to indent at each
                        level. If it is a string (such as '\t' or '&nbsp;'),
                        it contains the characters used to indent at each level.

            This method produces a JSON text from a JavaScript value.

            When an object value is found, if the object contains a toJSON
            method, its toJSON method will be called and the result will be
            stringified. A toJSON method does not serialize: it returns the
            value represented by the name/value pair that should be serialized,
            or undefined if nothing should be serialized. The toJSON method
            will be passed the key associated with the value, and this will be
            bound to the value

            For example, this would serialize Dates as ISO strings.

                Date.prototype.toJSON = function (key) {
                    function f(n) {
                        // Format integers to have at least two digits.
                        return n < 10 ? '0' + n : n;
                    }

                    return this.getUTCFullYear()   + '-' +
                         f(this.getUTCMonth() + 1) + '-' +
                         f(this.getUTCDate())      + 'T' +
                         f(this.getUTCHours())     + ':' +
                         f(this.getUTCMinutes())   + ':' +
                         f(this.getUTCSeconds())   + 'Z';
                };

            You can provide an optional replacer method. It will be passed the
            key and value of each member, with this bound to the containing
            object. The value that is returned from your method will be
            serialized. If your method returns undefined, then the member will
            be excluded from the serialization.

            If the replacer parameter is an array of strings, then it will be
            used to select the members to be serialized. It filters the results
            such that only members with keys listed in the replacer array are
            stringified.

            Values that do not have JSON representations, such as undefined or
            functions, will not be serialized. Such values in objects will be
            dropped; in arrays they will be replaced with null. You can use
            a replacer function to replace those with JSON values.
            JSON.stringify(undefined) returns undefined.

            The optional space parameter produces a stringification of the
            value that is filled with line breaks and indentation to make it
            easier to read.

            If the space parameter is a non-empty string, then that string will
            be used for indentation. If the space parameter is a number, then
            the indentation will be that many spaces.

            Example:

            text = JSON.stringify(['e', {pluribus: 'unum'}]);
            // text is '["e",{"pluribus":"unum"}]'


            text = JSON.stringify(['e', {pluribus: 'unum'}], null, '\t');
            // text is '[\n\t"e",\n\t{\n\t\t"pluribus": "unum"\n\t}\n]'

            text = JSON.stringify([new Date()], function (key, value) {
                return this[key] instanceof Date ?
                    'Date(' + this[key] + ')' : value;
            });
            // text is '["Date(---current time---)"]'


        JSON.parse(text, reviver)
            This method parses a JSON text to produce an object or array.
            It can throw a SyntaxError exception.

            The optional reviver parameter is a function that can filter and
            transform the results. It receives each of the keys and values,
            and its return value is used instead of the original value.
            If it returns what it received, then the structure is not modified.
            If it returns undefined then the member is deleted.

            Example:

            // Parse the text. Values that look like ISO date strings will
            // be converted to Date objects.

            myData = JSON.parse(text, function (key, value) {
                var a;
                if (typeof value === 'string') {
                    a =
/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}(?:\.\d*)?)Z$/.exec(value);
                    if (a) {
                        return new Date(Date.UTC(+a[1], +a[2] - 1, +a[3], +a[4],
                            +a[5], +a[6]));
                    }
                }
                return value;
            });

            myData = JSON.parse('["Date(09/09/2001)"]', function (key, value) {
                var d;
                if (typeof value === 'string' &&
                        value.slice(0, 5) === 'Date(' &&
                        value.slice(-1) === ')') {
                    d = new Date(value.slice(5, -1));
                    if (d) {
                        return d;
                    }
                }
                return value;
            });


    This is a reference implementation. You are free to copy, modify, or
    redistribute.
*/

/*jslint evil: true, regexp: true */

/*members "", "\b", "\t", "\n", "\f", "\r", "\"", JSON, "\\", apply,
    call, charCodeAt, getUTCDate, getUTCFullYear, getUTCHours,
    getUTCMinutes, getUTCMonth, getUTCSeconds, hasOwnProperty, join,
    lastIndex, length, parse, prototype, push, replace, slice, stringify,
    test, toJSON, toString, valueOf
*/


// Create a JSON object only if one does not already exist. We create the
// methods in a closure to avoid creating global variables.

if (typeof JSON !== 'object') {
    JSON = {};
}

(function () {
    'use strict';

    function f(n) {
        // Format integers to have at least two digits.
        return n < 10 ? '0' + n : n;
    }

    if (typeof Date.prototype.toJSON !== 'function') {

        Date.prototype.toJSON = function () {

            return isFinite(this.valueOf())
                ? this.getUTCFullYear()     + '-' +
                    f(this.getUTCMonth() + 1) + '-' +
                    f(this.getUTCDate())      + 'T' +
                    f(this.getUTCHours())     + ':' +
                    f(this.getUTCMinutes())   + ':' +
                    f(this.getUTCSeconds())   + 'Z'
                : null;
        };

        String.prototype.toJSON      =
            Number.prototype.toJSON  =
            Boolean.prototype.toJSON = function () {
                return this.valueOf();
            };
    }

    var cx,
        escapable,
        gap,
        indent,
        meta,
        rep;


    function quote(string) {

// If the string contains no control characters, no quote characters, and no
// backslash characters, then we can safely slap some quotes around it.
// Otherwise we must also replace the offending characters with safe escape
// sequences.

        escapable.lastIndex = 0;
        return escapable.test(string) ? '"' + string.replace(escapable, function (a) {
            var c = meta[a];
            return typeof c === 'string'
                ? c
                : '\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
        }) + '"' : '"' + string + '"';
    }


    function str(key, holder) {

// Produce a string from holder[key].

        var i,          // The loop counter.
            k,          // The member key.
            v,          // The member value.
            length,
            mind = gap,
            partial,
            value = holder[key];

// If the value has a toJSON method, call it to obtain a replacement value.

        if (value && typeof value === 'object' &&
                typeof value.toJSON === 'function') {
            value = value.toJSON(key);
        }

// If we were called with a replacer function, then call the replacer to
// obtain a replacement value.

        if (typeof rep === 'function') {
            value = rep.call(holder, key, value);
        }

// What happens next depends on the value's type.

        switch (typeof value) {
        case 'string':
            return quote(value);

        case 'number':

// JSON numbers must be finite. Encode non-finite numbers as null.

            return isFinite(value) ? String(value) : 'null';

        case 'boolean':
        case 'null':

// If the value is a boolean or null, convert it to a string. Note:
// typeof null does not produce 'null'. The case is included here in
// the remote chance that this gets fixed someday.

            return String(value);

// If the type is 'object', we might be dealing with an object or an array or
// null.

        case 'object':

// Due to a specification blunder in ECMAScript, typeof null is 'object',
// so watch out for that case.

            if (!value) {
                return 'null';
            }

// Make an array to hold the partial results of stringifying this object value.

            gap += indent;
            partial = [];

// Is the value an array?

            if (Object.prototype.toString.apply(value) === '[object Array]') {

// The value is an array. Stringify every element. Use null as a placeholder
// for non-JSON values.

                length = value.length;
                for (i = 0; i < length; i += 1) {
                    partial[i] = str(i, value) || 'null';
                }

// Join all of the elements together, separated with commas, and wrap them in
// brackets.

                v = partial.length === 0
                    ? '[]'
                    : gap
                    ? '[\n' + gap + partial.join(',\n' + gap) + '\n' + mind + ']'
                    : '[' + partial.join(',') + ']';
                gap = mind;
                return v;
            }

// If the replacer is an array, use it to select the members to be stringified.

            if (rep && typeof rep === 'object') {
                length = rep.length;
                for (i = 0; i < length; i += 1) {
                    if (typeof rep[i] === 'string') {
                        k = rep[i];
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (gap ? ': ' : ':') + v);
                        }
                    }
                }
            } else {

// Otherwise, iterate through all of the keys in the object.

                for (k in value) {
                    if (Object.prototype.hasOwnProperty.call(value, k)) {
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (gap ? ': ' : ':') + v);
                        }
                    }
                }
            }

// Join all of the member texts together, separated with commas,
// and wrap them in braces.

            v = partial.length === 0
                ? '{}'
                : gap
                ? '{\n' + gap + partial.join(',\n' + gap) + '\n' + mind + '}'
                : '{' + partial.join(',') + '}';
            gap = mind;
            return v;
        }
    }

// If the JSON object does not yet have a stringify method, give it one.

    if (typeof JSON.stringify !== 'function') {
        escapable = /[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g;
        meta = {    // table of character substitutions
            '\b': '\\b',
            '\t': '\\t',
            '\n': '\\n',
            '\f': '\\f',
            '\r': '\\r',
            '"' : '\\"',
            '\\': '\\\\'
        };
        JSON.stringify = function (value, replacer, space) {

// The stringify method takes a value and an optional replacer, and an optional
// space parameter, and returns a JSON text. The replacer can be a function
// that can replace values, or an array of strings that will select the keys.
// A default replacer method can be provided. Use of the space parameter can
// produce text that is more easily readable.

            var i;
            gap = '';
            indent = '';

// If the space parameter is a number, make an indent string containing that
// many spaces.

            if (typeof space === 'number') {
                for (i = 0; i < space; i += 1) {
                    indent += ' ';
                }

// If the space parameter is a string, it will be used as the indent string.

            } else if (typeof space === 'string') {
                indent = space;
            }

// If there is a replacer, it must be a function or an array.
// Otherwise, throw an error.

            rep = replacer;
            if (replacer && typeof replacer !== 'function' &&
                    (typeof replacer !== 'object' ||
                    typeof replacer.length !== 'number')) {
                throw new Error('JSON.stringify');
            }

// Make a fake root object containing our value under the key of ''.
// Return the result of stringifying the value.

            return str('', {'': value});
        };
    }


// If the JSON object does not yet have a parse method, give it one.

    if (typeof JSON.parse !== 'function') {
        cx = /[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g;
        JSON.parse = function (text, reviver) {

// The parse method takes a text and an optional reviver function, and returns
// a JavaScript value if the text is a valid JSON text.

            var j;

            function walk(holder, key) {

// The walk method is used to recursively walk the resulting structure so
// that modifications can be made.

                var k, v, value = holder[key];
                if (value && typeof value === 'object') {
                    for (k in value) {
                        if (Object.prototype.hasOwnProperty.call(value, k)) {
                            v = walk(value, k);
                            if (v !== undefined) {
                                value[k] = v;
                            } else {
                                delete value[k];
                            }
                        }
                    }
                }
                return reviver.call(holder, key, value);
            }


// Parsing happens in four stages. In the first stage, we replace certain
// Unicode characters with escape sequences. JavaScript handles many characters
// incorrectly, either silently deleting them, or treating them as line endings.

            text = String(text);
            cx.lastIndex = 0;
            if (cx.test(text)) {
                text = text.replace(cx, function (a) {
                    return '\\u' +
                        ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
                });
            }

// In the second stage, we run the text against regular expressions that look
// for non-JSON patterns. We are especially concerned with '()' and 'new'
// because they can cause invocation, and '=' because it can cause mutation.
// But just to be safe, we want to reject all unexpected forms.

// We split the second stage into 4 regexp operations in order to work around
// crippling inefficiencies in IE's and Safari's regexp engines. First we
// replace the JSON backslash pairs with '@' (a non-JSON character). Second, we
// replace all simple value tokens with ']' characters. Third, we delete all
// open brackets that follow a colon or comma or that begin the text. Finally,
// we look to see that the remaining characters are only whitespace or ']' or
// ',' or ':' or '{' or '}'. If that is so, then the text is safe for eval.

            if (/^[\],:{}\s]*$/
                    .test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@')
                        .replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']')
                        .replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {

// In the third stage we use the eval function to compile the text into a
// JavaScript structure. The '{' operator is subject to a syntactic ambiguity
// in JavaScript: it can begin a block or an object literal. We wrap the text
// in parens to eliminate the ambiguity.

                j = eval('(' + text + ')');

// In the optional fourth stage, we recursively walk the new structure, passing
// each name/value pair to a reviver function for possible transformation.

                return typeof reviver === 'function'
                    ? walk({'': j}, '')
                    : j;
            }

// If the text is not JSON parseable, then a SyntaxError is thrown.

            throw new SyntaxError('JSON.parse');
        };
    }
}());

/* global angular */
angular.module('algoliasearch', [])
  .service('algolia', ['$injector', function ($injector) {
    return {
      Client: function(applicationID, apiKey, options) {
        options = options || {};
        options.angular = {
          '$injector': $injector
        };
        options._ua = 'Algolia for AngularJS ' + window.ALGOLIA_VERSION;
        return new AlgoliaSearch(applicationID, apiKey, options);
      }
    };
  }]);
