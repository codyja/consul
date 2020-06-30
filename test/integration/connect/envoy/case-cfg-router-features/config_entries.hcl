enable_central_service_config = true

config_entries {
  bootstrap {
    kind = "proxy-defaults"
    name = "global"

    config {
      protocol = "http"
    }
  }

  bootstrap {
    kind           = "service-resolver"
    name           = "s2"
    default_subset = "v1"

    subsets = {
      "v1" = {
        filter = "Service.Meta.version == v1"
      }

      "v2" = {
        filter = "Service.Meta.version == v2"
      }
    }
  }

  bootstrap {
    kind = "service-router"
    name = "s2"

    routes = [
      {
        match { http { path_exact = "/exact/debug" } }
        destination {
          service_subset = "v2"
          prefix_rewrite = "/debug"
        }
      },
      {
        match { http { path_prefix = "/prefix/" } }
        destination {
          service_subset = "v2"
          prefix_rewrite = "/"
        }
      },
      {
        match { http {
          # path_regex = "/deb[ug]"
          path_exact = "/debug"
          header = [{
            name    = "x-test-debug"
            present = true
          }]
        } }
        destination {
          service_subset           = "v2"
          retry_on_connect_failure = true       # TODO: test
          retry_on_status_codes    = [500, 512] # TODO: test
        }
      },
      # TODO: test remainder
      # {
      #   match { http { header = [
      #     {
      #       name    = "foo0"
      #       present = true
      #     },
      #     {
      #       name  = "foo1"
      #       exact = "exact"
      #     },
      #     {
      #       name   = "foo2"
      #       prefix = "prefix"
      #     },
      #     {
      #       name   = "foo3"
      #       suffix = "suffix"
      #     },
      #     {
      #       name  = "foo4"
      #       regex = "regex"
      #     },
      #     {
      #       name   = "foo5"
      #       exact  = "exact"
      #       invert = true
      #     },
      #   ] } }
      #   destination {
      #     service_subset = "v2"
      #   }
      # },
      # {
      #   match { http {
      #     query_param = [
      #       {
      #         name    = "foo0"
      #         present = true
      #       },
      #       {
      #         name  = "foo1"
      #         exact = "exact"
      #       },
      #       {
      #         name  = "foo2"
      #         regex = "regex"
      #       },
      #     ]
      #   } }
      #   destination {
      #     service_subset = "v2"
      #   }
      # },
      # {
      #   match { http {
      #     methods = ["put", "delete"]
      #   } }
      #   destination {
      #     service_subset = "v2"
      #   }
      # },
    ]
  }
}
