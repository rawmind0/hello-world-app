package main

import (
	"fmt"
	"github.com/rawmind0/hello-world-app/templates"
	"net/http"
	"os"
	"regexp"
	"strings"
)

const (
	defaultListenPort = "8080"
	defaultDeploySep  = "-"
	defaultEnvSep     = "="
)

var (
	// VERSION gets overridden at build time using -X main.VERSION=$VERSION
	VERSION  = "dev"
	released = regexp.MustCompile(`^v[0-9]+\.[0-9]+\.[0-9]+$`)
)

type HelloWorldConfig struct {
	Podname    string
	Deployname string
	Services   map[string]string
	Headers    http.Header
	Nodename   string
	Host       string
	Version    string
}

func (config *HelloWorldConfig) GetManifest() (string, error) {
	return templates.CompileTemplateFromMap(templates.HelloWorldTemplate, config)
}

func (config *HelloWorldConfig) getServices() {
	k8sServices := make(map[string]string)

	deployPrefix := strings.Replace(strings.ToUpper(config.Deployname), defaultDeploySep, "_", -1)
	for _, evar := range os.Environ() {
		show := strings.Split(evar, defaultEnvSep)
		regName := regexp.MustCompile("^" + deployPrefix + ".*_PORT$")
		regLink := regexp.MustCompile("^(tcp|udp)://.*")
		if regName.MatchString(show[0]) && regLink.MatchString(show[1]) {
			k8sServices[strings.TrimSuffix(show[0], "_PORT")] = show[1]
		}

	}

	config.Services = k8sServices
}

func (config *HelloWorldConfig) getDeployName() {
	serviceName := ""
	if len(config.Podname) > 0 {
		deployNameFull := strings.Split(config.Podname, defaultDeploySep)
		deployNameLen := len(deployNameFull)
		if deployNameLen < 2 {
			serviceName = config.Podname
		} else {
			for _, name := range deployNameFull[:len(deployNameFull)-2] {
				if len(serviceName) == 0 {
					serviceName = name
					continue
				}
				serviceName = serviceName + defaultDeploySep + name
			}
		}
	}
	config.Deployname = serviceName
}

func (config *HelloWorldConfig) Init(r *http.Request) {
	config.Podname, _ = os.Hostname()
	config.Nodename = os.Getenv("MY_NODE_IP")
	config.Host = r.Host
	config.Headers = r.Header
	config.Version = VERSION
	config.getDeployName()
	config.getServices()
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	config := &HelloWorldConfig{}
	config.Init(r)
	data, err := config.GetManifest()
	if err != nil {
		fmt.Fprintln(w, err)
	}

	fmt.Fprint(w, data)
}

func versionHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, VERSION)
}

func main() {
	webPort := os.Getenv("HTTP_PORT")
	if webPort == "" {
		webPort = defaultListenPort
	}

	fmt.Println("Running http service at", webPort, "port")
	http.HandleFunc("/", helloHandler)
	http.HandleFunc("/version", versionHandler)
	http.Handle("/img/", http.StripPrefix("/img/", http.FileServer(http.Dir(os.Getenv("PWD")))))
	http.ListenAndServe(":"+webPort, nil)
}
