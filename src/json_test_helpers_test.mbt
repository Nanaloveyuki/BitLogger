///|
fn Json::expect_json_object(self : Json) -> Map[String, Json] {
  match self {
    Json::Object(value) => value
    _ => abort("Expected JSON object")
  }
}

///|
fn Json::expect_json_number(self : Json) -> Double {
  match self {
    Json::Number(value, ..) => value
    _ => abort("Expected JSON number")
  }
}

///|
fn Json::expect_json_string(self : Json) -> String {
  match self {
    Json::String(value) => value
    _ => abort("Expected JSON string")
  }
}

///|
fn Json::expect_json_bool(self : Json) -> Bool {
  match self {
    Json::True => true
    Json::False => false
    _ => abort("Expected JSON bool")
  }
}
