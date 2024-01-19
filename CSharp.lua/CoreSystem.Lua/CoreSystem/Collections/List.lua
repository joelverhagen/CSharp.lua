--[[
Copyright 2017 YANG Huan (sy.yanghuan@gmail.com).

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]

local System = System
local define = System.define
local throw = System.throw
local falseFn = System.falseFn
local Array = System.Array
local er = System.er

local InvalidOperationException = System.InvalidOperationException
local NullReferenceException = System.NullReferenceException
local ArgumentException = System.ArgumentException
local ArgumentNullException = System.ArgumentNullException
local ArgumentOutOfRangeException = System.ArgumentOutOfRangeException
local IEnumerator_1 = System.IEnumerator_1

local tmove = table.move

local function throwFailedVersion()
  throw(InvalidOperationException("Collection was modified; enumeration operation may not execute."))
end

local ListEnumerator = define("System.ListEnumerator", function (T)
  return {
    base = { IEnumerator_1(T) }
  }
end, {
  getCurrent = System.getCurrent, 
  Dispose = System.emptyFn,
  Reset = function (this)
    this.index = 1
    this.current = nil
  end,
  MoveNext = function (this)
    local t = this.list
    if this.version ~= t._version then
      throwFailedVersion()
    end
    local index = this.index
    local v = t[index]
    if v ~= nil then
      if v == null then
        this.current = nil
      else
        this.current = v
      end
      this.index = index + 1
      return true
    end
    this.current = nil
    return false
  end
}, 1)

local listEnumerator

listEnumerator = function (t, T)
  if not T then T = t.__genericT__ end
  return setmetatable({ list = t, index = 1, version = t.version, currnet = T:default() }, ListEnumerator(T))
end

local function ipairs(t)
  local version = t._version
  return function (t, i)
    if version ~= t._version then
      throwFailedVersion()
    end
    local v = t[i]
    if v ~= nil then
      if v == null then
        v = nil
      end
      return i + 1, v
    end
  end, t, 1
end

local function eachFn(en)
  if en:MoveNext() then
    return true, en:getCurrent()
  end
  return nil
end

local function each(t)
  if t == nil then throw(NullReferenceException(), 1) end
  local getEnumerator = t.GetEnumerator
  if getEnumerator == listEnumerator then
    return ipairs(t)
  end
  local en = getEnumerator(t)
  return eachFn, en
end

local function lengthFn(t)
  return t._length
end

local function addRange(t, collection)
  if collection == nil then throw(ArgumentNullException("collection")) end
  local count = t._length + 1
  if collection.GetEnumerator == listEnumerator then
    tmove(collection, 1, collection._length, count, t)
    count = count + collection._length
  else
    for _, v in each(collection) do
      t[count] = v
      count = count + 1
    end
  end
  t._length = count - 1
  t._version = t._version + 1
end

local function listCtor(t, ...)
  local n = select("#", ...)
  if n == 0 then return end
  local collection = ...
  if type(collection) == "number" then return end
  addRange(t, collection)
end

local function setCapacity(t, len)
  if len < t._length then throw(ArgumentOutOfRangeException("Value", er.ArgumentOutOfRange_SmallCapacity())) end
end

local function get(t, index)
  index = index + 1
  if index < 1 or index > t._length then
    throw(ArgumentOutOfRangeException("index"))
  end
  return t[index]
end

local function set(t, index, v)
  index = index + 1
  if index < 1 or index > t._length then
    throw(ArgumentOutOfRangeException("index"))
  end
  t[index] = v
  t._version = t._version + 1
end

local function add(t, v)
  local n = t._length + 1
  t[n] = v
  t._length = n
  t._version = t._version + 1
end

local function addObj(this, item)
  if not System.is(item, this.__genericT__) then
    throw(ArgumentException())
  end
  return add(this, item)
end

local function asReadOnly(t)
  return System.ReadOnlyCollection(t.__genericT__)(t)
end

local List = {
  __ctor__ = listCtor,
  getCapacity = lengthFn,
  setCapacity = setCapacity,
  getCount = lengthFn,
  getIsFixedSize = falseFn,
  getIsReadOnly = falseFn,
  get = get,
  set = set,
  Add = add,
  AddObj = addObj,
  AddRange = addRange,
  AsReadOnly = asReadOnly,
  BinarySearch = Array.BinarySearch,
  Clear = Array.clear,
  Contains = Array.Contains,
  CopyTo = Array.CopyTo,
  Exists = Array.Exists,
  Find = Array.Find,
  FindAll = Array.findAll,
  FindIndex = Array.FindIndex,
  FindLast = Array.FindLast,
  FindLastIndex = Array.FindLastIndex,
  ForEach = Array.ForEach,
  GetEnumerator = Array.GetEnumerator,
  GetRange = Array.getRange,
  IndexOf = Array.IndexOf,
  Insert = Array.insert,
  InsertRange = Array.insertRange,
  LastIndexOf = Array.LastIndexOf,
  Remove = Array.remove,
  RemoveAll = Array.removeAll,
  RemoveAt = Array.removeAt,
  RemoveRange = Array.removeRange,
  Reverse = Array.Reverse,
  Sort = Array.Sort,
  TrimExcess = System.emptyFn,
  ToArray = Array.toArray,
  TrueForAll = Array.TrueForAll
}

function System.listFromTable(t, T)
  return setmetatable(t, List(T))
end

local ListFn = System.define("System.Collections.Generic.List", function(T)
  return {
    base = { System.IList_1(T), System.IReadOnlyList_1(T), System.IList },
    __genericT__ = T,
  }
end, List, 1)

System.List = ListFn
System.ArrayList = ListFn(System.Object)
