import {
  inbox_message_attachment_path,
  inboxes_path,
  serialize,
  configure,
  config,
} from "./routes.spec";

// Route Helpers
inboxes_path();
inboxes_path({
  locale: "en",
  search: {
    q: "ukraine",
    page: 3,
    keywords: ["large", "small", { advanced: true }],
  },
});

inbox_message_attachment_path(1, "2", true);
inbox_message_attachment_path(
  { id: 1 },
  { to_param: () => "2" },
  { toParam: () => true }
);
inbox_message_attachment_path(1, "2", true, { format: "json" });
inboxes_path.toString();
inboxes_path.requiredParams();

// serialize test
const SerializerArgument = {
  locale: "en",
  search: {
    q: "ukraine",
    page: 3,
    keywords: ["large", "small", { advanced: true }],
  },
};
serialize(SerializerArgument);
config().serializer(SerializerArgument);

// configure test
configure({
  default_url_options: { port: 1, host: null },
  prefix: "",
  special_options_key: "_options",
  serializer: (value) => JSON.stringify(value),
});

// config tests
const Config = config();
console.log(
  Config.prefix,
  Config.default_url_options,
  Config.special_options_key
);
