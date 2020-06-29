package xds

import (
	"fmt"

	envoy "github.com/envoyproxy/go-control-plane/envoy/api/v2"
	envoycore "github.com/envoyproxy/go-control-plane/envoy/api/v2/core"
	"github.com/hashicorp/go-version"
)

var (
	minSafeRegexVersion = version.Must(version.NewVersion("1.12.0"))
)

type supportedProxyFeatures struct {
	RouterMatchSafeRegex bool // use safe_regex instead of regex in http.router rules
}

func determineSupportedProxyFeatures(req *envoy.DiscoveryRequest) supportedProxyFeatures {
	version := determineEnvoyVersion(req)
	if version == nil {
		return supportedProxyFeatures{}
	}

	return supportedProxyFeatures{
		RouterMatchSafeRegex: !version.LessThan(minSafeRegexVersion),
	}
}

func determineEnvoyVersion(req *envoy.DiscoveryRequest) *version.Version {
	node := req.Node

	if node.UserAgentName != "envoy" {
		return nil
	}
	// TODO: check that UserAgentName == "envoy"?

	if node.UserAgentVersionType == nil {
		// TODO: check BuildVersion?
		return nil
	}

	bv, ok := node.UserAgentVersionType.(*envoycore.Node_UserAgentBuildVersion)
	if !ok {
		// NOTE: we could sniff for *envoycore.Node_UserAgentVersion and do more regex but official builds don't have this problem.
		return nil
	}
	if bv.UserAgentBuildVersion == nil {
		return nil
	}
	v := bv.UserAgentBuildVersion.Version

	return version.Must(version.NewVersion(
		fmt.Sprintf("%d.%d.%d",
			v.GetMajorNumber(),
			v.GetMinorNumber(),
			v.GetPatch(),
		),
	))

}
