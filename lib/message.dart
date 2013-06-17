part of collab;

//  Copyright 2011 Google Inc. All Rights Reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.


/**
 * Defines the basic [Message] class.
 */

String SERVER_ID = "_server";

/**
 * Deserialize JSON messages to [Map]s.
 */
final StreamTransformer<dynamic, Map> JSON_TO_MAP =
    new StreamTransformer(handleData: (value, sink) {
      var json = JSON.parse(value);
      if (json is! Map) {
        sink.addError("Invalid Message: value");
      } else {
        sink.add(json);
      }
    });

/**
 * Messages are sent between clients and servers.
 */
class Message {
  final String id;
  final String senderId;
  // id of the messgage this is in reply to. can be null.
  final String replyTo;
  final String type;

  Message(this.type, this.senderId, [String replyTo])
    : id = randomId(),
      this.replyTo = replyTo;

  Message.fromMap(Map<String, Object> map)
    : id = map['id'],
      senderId = map['senderId'],
      replyTo = map['replyTo'],
      type = map['type'];

  /**
   * Returns a JSON representation of the message.
   */
  String get json => JSON.stringify(toMap());

  String toString() => "Message $json";

  /**
   * Returns a [JSON.stringify] or Isolate SendPort compatible map
   * of String-> bool, String, num, List, Map.
   *
   * [values] is merged into the result so that subclasses can call toMap() with
   * additional values.
   */
  Map<String, Object> toMap([Map<String, Object> values]) {
    Map m = mergeMaps(values, {'type': type, 'id': id, 'senderId': senderId});
    if (replyTo != null) {
      m['replyTo'] = replyTo;
    }
    return m;
  }
}

typedef Message MessageFactory(Map<String, Object> map);

class SystemMessageParser {
  static final Map<String, MessageFactory> _messageFactories = {
    "log": (m) => new LogMessage.fromMap(m),
    "create": (m) => new CreateMessage.fromMap(m),
    "created": (m) => new CreatedMessage.fromMap(m),
    "clientId": (m) => new ClientIdMessage.fromMap(m),
    "open": (m) => new OpenMessage.fromMap(m),
    "close": (m) => new CloseMessage.fromMap(m),
    "snapshot": (m) => new SnapshotMessage.fromMap(m),
  };

  /**
   * Parses [json] and returns the correct subtype of [Message].
   *
   * In order for parse() to return the correct Message subtype a factory
   * function must be registered.
   */
  static Message parse(Map json) {
    String type = json['type'];
    var factory = _messageFactories[type];
    if (factory != null) {
      return factory(json);
    }
    return null;
  }
}
