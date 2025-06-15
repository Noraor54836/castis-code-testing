import React, { useState, useEffect } from "react";
import "./App.css";

const APISIX_ADMIN_URL =
  process.env.REACT_APP_APISIX_ADMIN_URL || "http://localhost:9091";
const ADMIN_KEY = process.env.REACT_APP_ADMIN_KEY || "your-admin-key-here";

function App() {
  const [routes, setRoutes] = useState([]);
  const [upstreams, setUpstreams] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [activeTab, setActiveTab] = useState("routes");
  const [showCreateRoute, setShowCreateRoute] = useState(false);
  const [newRoute, setNewRoute] = useState({
    uri: "",
    name: "",
    methods: ["GET"],
    upstream: {
      type: "roundrobin",
      nodes: {},
    },
  });

  // Fetch routes from APISIX Admin API
  const fetchRoutes = async () => {
    setLoading(true);
    try {
      const response = await fetch(`${APISIX_ADMIN_URL}/apisix/admin/routes`, {
        headers: {
          "X-API-KEY": ADMIN_KEY,
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      setRoutes(data.list || []);
      setError("");
    } catch (err) {
      setError(`Failed to delete route: ${err.message}`);
    }
  };

  // Fetch upstreams from APISIX Admin API
  const fetchUpstreams = async () => {
    setLoading(true);
    try {
      const response = await fetch(
        `${APISIX_ADMIN_URL}/apisix/admin/upstreams`,
        {
          headers: {
            "X-API-KEY": ADMIN_KEY,
            "Content-Type": "application/json",
          },
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      setUpstreams(data.list || []);
      setError("");
    } catch (err) {
      setError(`Failed to fetch upstreams: ${err.message}`);
      console.error("Error fetching upstreams:", err);
    } finally {
      setLoading(false);
    }
  };

  // Add node to upstream
  const addUpstreamNode = () => {
    const host = document.getElementById("upstream-host").value;
    const port = document.getElementById("upstream-port").value;
    const weight = document.getElementById("upstream-weight").value || 1;

    if (!host || !port) {
      setError("Host and port are required for upstream node");
      return;
    }

    const nodeKey = `${host}:${port}`;
    setNewRoute((prev) => ({
      ...prev,
      upstream: {
        ...prev.upstream,
        nodes: {
          ...prev.upstream.nodes,
          [nodeKey]: parseInt(weight),
        },
      },
    }));

    // Clear inputs
    document.getElementById("upstream-host").value = "";
    document.getElementById("upstream-port").value = "";
    document.getElementById("upstream-weight").value = "";
  };

  // Remove node from upstream
  const removeUpstreamNode = (nodeKey) => {
    setNewRoute((prev) => {
      const newNodes = { ...prev.upstream.nodes };
      delete newNodes[nodeKey];
      return {
        ...prev,
        upstream: {
          ...prev.upstream,
          nodes: newNodes,
        },
      };
    });
  };

  // Initialize data on component mount
  useEffect(() => {
    fetchRoutes();
    fetchUpstreams();
  }, []);

  // Predefined route templates
  const routeTemplates = [
    {
      name: "WordPress API Route",
      uri: "/api/posts",
      upstream: {
        type: "roundrobin",
        nodes: { "wordpress:80": 1 },
      },
      plugins: {
        "proxy-rewrite": {
          regex_uri: ["/api/posts", "/wp-json/wp/v2/posts"],
        },
      },
    },
    {
      name: "GoFiber Backend Route",
      uri: "/api/data/*",
      upstream: {
        type: "roundrobin",
        nodes: { "gofiber-backend:8080": 1 },
      },
      plugins: {
        "key-auth": {},
      },
    },
  ];

  const applyTemplate = (template) => {
    setNewRoute({
      ...template,
      methods: ["GET", "POST", "PUT", "DELETE"],
    });
  };

  // Create a new route
  const createRoute = async () => {
    if (!newRoute.uri || !newRoute.name) {
      setError("URI and Name are required");
      return;
    }

    try {
      const routeData = {
        ...newRoute,
        upstream: {
          ...newRoute.upstream,
          nodes: newRoute.upstream.nodes,
        },
      };

      const response = await fetch(`${APISIX_ADMIN_URL}/apisix/admin/routes`, {
        method: "POST",
        headers: {
          "X-API-KEY": ADMIN_KEY,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(routeData),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      setShowCreateRoute(false);
      setNewRoute({
        uri: "",
        name: "",
        methods: ["GET"],
        upstream: {
          type: "roundrobin",
          nodes: {},
        },
      });
      fetchRoutes();
      setError("");
    } catch (err) {
      setError(`Failed to create route: ${err.message}`);
    }
  };

  // Delete a route
  const deleteRoute = async (routeId) => {
    if (!window.confirm("Are you sure you want to delete this route?")) {
      return;
    }

    try {
      const response = await fetch(
        `${APISIX_ADMIN_URL}/apisix/admin/routes/${routeId}`,
        {
          method: "DELETE",
          headers: {
            "X-API-KEY": ADMIN_KEY,
          },
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      fetchRoutes();
      setError("");
    } catch (err) {
      console.error("Error deleting route:", err);
    }
  };

  return (
    <div className="App">
      <header className="app-header">
        <h1>🚀 APISIX Custom Dashboard</h1>
        <p>Manage your API Gateway routes and upstreams</p>
      </header>

      <div className="container">
        {error && (
          <div className="error-banner">
            <span>⚠️ {error}</span>
            <button onClick={() => setError("")}>×</button>
          </div>
        )}

        <div className="tabs">
          <button
            className={activeTab === "routes" ? "tab active" : "tab"}
            onClick={() => setActiveTab("routes")}
          >
            📝 Routes ({routes.length})
          </button>
          <button
            className={activeTab === "upstreams" ? "tab active" : "tab"}
            onClick={() => setActiveTab("upstreams")}
          >
            🔗 Upstreams ({upstreams.length})
          </button>
          <button
            className={activeTab === "test" ? "tab active" : "tab"}
            onClick={() => setActiveTab("test")}
          >
            🧪 API Test
          </button>
        </div>

        {activeTab === "routes" && (
          <div className="tab-content">
            <div className="section-header">
              <h2>Routes Management</h2>
              <div className="actions">
                <button
                  onClick={fetchRoutes}
                  disabled={loading}
                  className="btn-secondary"
                >
                  {loading ? "🔄 Loading..." : "🔄 Refresh"}
                </button>
                <button
                  onClick={() => setShowCreateRoute(true)}
                  className="btn-primary"
                >
                  ➕ Create Route
                </button>
              </div>
            </div>

            {showCreateRoute && (
              <div className="modal-overlay">
                <div className="modal">
                  <div className="modal-header">
                    <h3>Create New Route</h3>
                    <button
                      onClick={() => setShowCreateRoute(false)}
                      className="close-btn"
                    >
                      ×
                    </button>
                  </div>

                  <div className="modal-body">
                    <div className="templates-section">
                      <h4>Quick Templates</h4>
                      <div className="templates">
                        {routeTemplates.map((template, index) => (
                          <button
                            key={index}
                            onClick={() => applyTemplate(template)}
                            className="template-btn"
                          >
                            {template.name}
                          </button>
                        ))}
                      </div>
                    </div>

                    <div className="form-group">
                      <label>Route Name *</label>
                      <input
                        type="text"
                        value={newRoute.name}
                        onChange={(e) =>
                          setNewRoute({ ...newRoute, name: e.target.value })
                        }
                        placeholder="e.g., WordPress Posts API"
                      />
                    </div>

                    <div className="form-group">
                      <label>URI Pattern *</label>
                      <input
                        type="text"
                        value={newRoute.uri}
                        onChange={(e) =>
                          setNewRoute({ ...newRoute, uri: e.target.value })
                        }
                        placeholder="e.g., /api/posts or /api/data/*"
                      />
                    </div>

                    <div className="form-group">
                      <label>HTTP Methods</label>
                      <div className="methods-group">
                        {["GET", "POST", "PUT", "DELETE", "PATCH"].map(
                          (method) => (
                            <label key={method} className="checkbox-label">
                              <input
                                type="checkbox"
                                checked={newRoute.methods.includes(method)}
                                onChange={(e) => {
                                  if (e.target.checked) {
                                    setNewRoute({
                                      ...newRoute,
                                      methods: [...newRoute.methods, method],
                                    });
                                  } else {
                                    setNewRoute({
                                      ...newRoute,
                                      methods: newRoute.methods.filter(
                                        (m) => m !== method
                                      ),
                                    });
                                  }
                                }}
                              />
                              {method}
                            </label>
                          )
                        )}
                      </div>
                    </div>

                    <div className="form-group">
                      <label>Upstream Nodes</label>
                      <div className="upstream-builder">
                        <div className="upstream-inputs">
                          <input
                            id="upstream-host"
                            type="text"
                            placeholder="Host (e.g., wordpress, gofiber-backend)"
                          />
                          <input
                            id="upstream-port"
                            type="number"
                            placeholder="Port (e.g., 80, 8080)"
                          />
                          <input
                            id="upstream-weight"
                            type="number"
                            placeholder="Weight (default: 1)"
                            min="1"
                          />
                          <button
                            type="button"
                            onClick={addUpstreamNode}
                            className="btn-secondary"
                          >
                            Add Node
                          </button>
                        </div>

                        <div className="upstream-nodes">
                          {Object.entries(newRoute.upstream.nodes).map(
                            ([nodeKey, weight]) => (
                              <div key={nodeKey} className="upstream-node">
                                <span>
                                  {nodeKey} (weight: {weight})
                                </span>
                                <button
                                  onClick={() => removeUpstreamNode(nodeKey)}
                                  className="remove-btn"
                                >
                                  Remove
                                </button>
                              </div>
                            )
                          )}
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="modal-footer">
                    <button
                      onClick={() => setShowCreateRoute(false)}
                      className="btn-secondary"
                    >
                      Cancel
                    </button>
                    <button onClick={createRoute} className="btn-primary">
                      Create Route
                    </button>
                  </div>
                </div>
              </div>
            )}

            <div className="routes-grid">
              {routes.length === 0 ? (
                <div className="empty-state">
                  <p>No routes configured yet. Create your first route!</p>
                </div>
              ) : (
                routes.map((route) => (
                  <div key={route.value.id} className="route-card">
                    <div className="route-header">
                      <h3>{route.value.name || `Route ${route.value.id}`}</h3>
                      <button
                        onClick={() => deleteRoute(route.value.id)}
                        className="delete-btn"
                        title="Delete Route"
                      >
                        🗑️
                      </button>
                    </div>
                    <div className="route-details">
                      <div className="detail-item">
                        <strong>URI:</strong> {route.value.uri}
                      </div>
                      <div className="detail-item">
                        <strong>Methods:</strong>
                        <div className="methods">
                          {route.value.methods?.map((method) => (
                            <span key={method} className="method-badge">
                              {method}
                            </span>
                          )) || <span className="method-badge">ALL</span>}
                        </div>
                      </div>
                      {route.value.upstream && (
                        <div className="detail-item">
                          <strong>Upstream:</strong>
                          <div className="upstream-info">
                            <div>Type: {route.value.upstream.type}</div>
                            <div>
                              Nodes:{" "}
                              {Object.keys(
                                route.value.upstream.nodes || {}
                              ).join(", ")}
                            </div>
                          </div>
                        </div>
                      )}
                      {route.value.plugins &&
                        Object.keys(route.value.plugins).length > 0 && (
                          <div className="detail-item">
                            <strong>Plugins:</strong>
                            <div className="plugins">
                              {Object.keys(route.value.plugins).map(
                                (plugin) => (
                                  <span key={plugin} className="plugin-badge">
                                    {plugin}
                                  </span>
                                )
                              )}
                            </div>
                          </div>
                        )}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        )}

        {activeTab === "upstreams" && (
          <div className="tab-content">
            <div className="section-header">
              <h2>Upstreams Management</h2>
              <button
                onClick={fetchUpstreams}
                disabled={loading}
                className="btn-secondary"
              >
                {loading ? "🔄 Loading..." : "🔄 Refresh"}
              </button>
            </div>

            <div className="upstreams-grid">
              {upstreams.length === 0 ? (
                <div className="empty-state">
                  <p>No upstreams configured yet.</p>
                </div>
              ) : (
                upstreams.map((upstream) => (
                  <div key={upstream.value.id} className="upstream-card">
                    <div className="upstream-header">
                      <h3>Upstream {upstream.value.id}</h3>
                    </div>
                    <div className="upstream-details">
                      <div className="detail-item">
                        <strong>Type:</strong> {upstream.value.type}
                      </div>
                      <div className="detail-item">
                        <strong>Nodes:</strong>
                        <ul className="nodes-list">
                          {Object.entries(upstream.value.nodes || {}).map(
                            ([node, weight]) => (
                              <li key={node}>
                                {node} (weight: {weight})
                              </li>
                            )
                          )}
                        </ul>
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        )}

        {activeTab === "test" && (
          <div className="tab-content">
            <APITester />
          </div>
        )}
      </div>
    </div>
  );
}

// API Testing Component
function APITester() {
  const [testUrl, setTestUrl] = useState("http://localhost:9080/api/data");
  const [testMethod, setTestMethod] = useState("GET");
  const [testHeaders, setTestHeaders] = useState("{}");
  const [testBody, setTestBody] = useState("{}");
  const [testResponse, setTestResponse] = useState("");
  const [testLoading, setTestLoading] = useState(false);

  const runTest = async () => {
    setTestLoading(true);
    try {
      let headers = {};
      try {
        headers = JSON.parse(testHeaders);
      } catch (e) {
        headers = { "Content-Type": "application/json" };
      }

      const options = {
        method: testMethod,
        headers: headers,
      };

      if (testMethod !== "GET" && testBody) {
        options.body = testBody;
      }

      const response = await fetch(testUrl, options);
      const responseText = await response.text();

      const result = {
        status: response.status,
        statusText: response.statusText,
        headers: Object.fromEntries(response.headers.entries()),
        body: responseText,
      };

      setTestResponse(JSON.stringify(result, null, 2));
    } catch (error) {
      setTestResponse(`Error: ${error.message}`);
    } finally {
      setTestLoading(false);
    }
  };

  const predefinedTests = [
    {
      name: "Test GoFiber Health",
      url: "http://localhost:9080/health",
      method: "GET",
      headers: '{"Content-Type": "application/json"}',
      body: "",
    },
    {
      name: "Get Records",
      url: "http://localhost:9080/api/data",
      method: "GET",
      headers: '{"Content-Type": "application/json"}',
      body: "",
    },
    {
      name: "Create Record",
      url: "http://localhost:9080/api/data",
      method: "POST",
      headers: '{"Content-Type": "application/json"}',
      body: '{"name": "Test Record", "value": "This is a test record from dashboard"}',
    },
    {
      name: "WordPress Posts",
      url: "http://localhost:9080/api/posts",
      method: "GET",
      headers: '{"Content-Type": "application/json"}',
      body: "",
    },
  ];

  const loadPredefinedTest = (test) => {
    setTestUrl(test.url);
    setTestMethod(test.method);
    setTestHeaders(test.headers);
    setTestBody(test.body);
  };

  return (
    <div className="api-tester">
      <div className="section-header">
        <h2>API Testing Tool</h2>
        <p>Test your API endpoints through APISIX gateway</p>
      </div>

      <div className="predefined-tests">
        <h3>Quick Tests</h3>
        <div className="test-buttons">
          {predefinedTests.map((test, index) => (
            <button
              key={index}
              onClick={() => loadPredefinedTest(test)}
              className="test-btn"
            >
              {test.name}
            </button>
          ))}
        </div>
      </div>

      <div className="test-form">
        <div className="form-row">
          <div className="form-group">
            <label>Method</label>
            <select
              value={testMethod}
              onChange={(e) => setTestMethod(e.target.value)}
            >
              <option value="GET">GET</option>
              <option value="POST">POST</option>
              <option value="PUT">PUT</option>
              <option value="DELETE">DELETE</option>
              <option value="PATCH">PATCH</option>
            </select>
          </div>
          <div className="form-group flex-grow">
            <label>URL</label>
            <input
              type="text"
              value={testUrl}
              onChange={(e) => setTestUrl(e.target.value)}
              placeholder="http://localhost:9080/api/..."
            />
          </div>
        </div>

        <div className="form-group">
          <label>Headers (JSON)</label>
          <textarea
            value={testHeaders}
            onChange={(e) => setTestHeaders(e.target.value)}
            placeholder='{"Content-Type": "application/json", "X-API-Key": "your-key"}'
            rows="3"
          />
        </div>

        {testMethod !== "GET" && (
          <div className="form-group">
            <label>Request Body (JSON)</label>
            <textarea
              value={testBody}
              onChange={(e) => setTestBody(e.target.value)}
              placeholder='{"key": "value"}'
              rows="4"
            />
          </div>
        )}

        <button
          onClick={runTest}
          disabled={testLoading}
          className="btn-primary"
        >
          {testLoading ? "🔄 Testing..." : "🚀 Send Request"}
        </button>
      </div>

      {testResponse && (
        <div className="test-response">
          <h3>Response</h3>
          <pre>{testResponse}</pre>
        </div>
      )}
    </div>
  );
}

export default App;
