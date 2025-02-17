// Copyright (c) 2017-2022 Cloudflare, Inc.
// Licensed under the Apache 2.0 license found in the LICENSE file or at:
//     https://opensource.org/licenses/Apache-2.0

#pragma once

#include <initializer_list>
#include <kj/array.h>
#include <kj/string.h>
#include <workerd/io/compatibility-date.h>
#include <workerd/jsg/modules.h>
#include <workerd/jsg/rtti.h>

namespace workerd::api {

class RTTIModule final: public jsg::Object {
public:
  kj::Array<byte> exportTypes(kj::String compatDate, kj::Array<kj::String> compatFlags);

  JSG_RESOURCE_TYPE(RTTIModule) {
    JSG_METHOD(exportTypes);
  }
};

template <class Registry>
void registerRTTIModule(Registry& registry) {
  registry.template addBuiltinModule<RTTIModule>("workerd:rtti",
    workerd::jsg::ModuleRegistry::Type::BUILTIN);
}

#define EW_RTTI_ISOLATE_TYPES api::RTTIModule

} // namespace workerd::api
