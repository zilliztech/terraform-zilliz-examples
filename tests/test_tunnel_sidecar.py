"""Offline rendering checks for the Azure BYOC-I bootstrap artifact."""
import json
import pathlib
import subprocess
import tempfile
import unittest
import zipfile

import yaml

ROOT = pathlib.Path(__file__).resolve().parents[1]
CHART = ROOT / 'modules/azure/byoc_i/default-aks/agent-charts'


def render(chart, image):
    result = subprocess.run([
        'helm', 'template', 'cloud-agent', str(chart),
        '--set-string', f'tunnelClient.image={image}',
        '--set-string', 'config.tunnel.authToken=test-token',
        '--set-string', 'config.tunnel.dataPlaneId=test-plane',
        '--set-string', 'rbac.maintenanceClientId=test-client',
    ], check=True, text=True, capture_output=True)
    return [d for d in yaml.safe_load_all(result.stdout) if d]


class TunnelSidecarTest(unittest.TestCase):
    def test_split_and_legacy(self):
        for image in ['', '   ', 'registry.example/vdc/cloud-tunnel-client:test']:
            with self.subTest(image=image):
                docs = render(CHART, image)
                configs = {d['metadata']['name']: yaml.safe_load(d['data']['application.yml'])
                           for d in docs if d['kind'] == 'ConfigMap'}
                deployments = [d for d in docs if d['kind'] == 'Deployment']
                self.assertEqual(len(deployments), 2)
                for d in deployments:
                    name = d['metadata']['name']
                    spec = d['spec']
                    pod = spec['template']['spec']
                    containers = {c['name']: c for c in pod['containers']}
                    self.assertIn('kubectl-proxy', containers)
                    config_name = next(v['configMap']['name'] for v in pod['volumes'] if v['name'] == 'spring-config')
                    self.assertEqual(config_name, name)
                    self.assertEqual(configs[name]['byoc']['tunnel']['srvNo'], 2 if name.endswith('backup') else 1)
                    if not image.strip():
                        self.assertNotIn('tunnel-client', containers)
                        self.assertNotIn('strategy', spec)
                        continue
                    self.assertEqual(spec['strategy'], {'type': 'Recreate'})
                    selector = spec['selector']['matchLabels']
                    self.assertEqual(selector, spec['template']['metadata']['labels'])
                    self.assertEqual(selector, {'app.kubernetes.io/name': 'cloud-agent', 'app.kubernetes.io/instance': 'vdc'})
                    sidecar = containers['tunnel-client']
                    agent = containers['cloud-agent']
                    self.assertEqual(sidecar['image'], image)
                    self.assertEqual(sidecar['resources'], agent['resources'])
                    self.assertEqual(sidecar['volumeMounts'], agent['volumeMounts'])
                    env = {e['name']: e['value'] for e in sidecar['env']}
                    self.assertEqual(env['SERVER_ADDRESS'], '127.0.0.1')
                    self.assertEqual(env['SERVER_PORT'], '9999')
                    self.assertEqual(env['SPRING_CONFIG_ADDITIONAL_LOCATION'], 'file:///spring-config/application.yml')
                    self.assertEqual(env['BYOC_K8S_KEY'], 'test-token')
                    self.assertEqual(env['SPRING_APPLICATION_NAME'], 'tunnel-client-app')
                    self.assertIn('http://127.0.0.1:9999/cloud/check_healthy_db', sidecar['readinessProbe']['exec']['command'])
                    self.assertEqual(d['metadata']['annotations']['configmap.reloader.stakater.com/reload'], name)

    def test_terraform_resolves_gcp_image(self):
        source = (ROOT / 'examples/gcp-project-byoc-I/locals.tf').read_text()
        expressions = source[source.index('  tunnel_client_image_url'):source.index('  agent_image_tag =')]
        expressions = expressions.replace('data.zillizcloud_byoc_i_project_settings.this.op_config', 'local.api_config')
        cases = [
            (None, '', ''), ('', '', ''), ('   ', '', ''),
            ('split-v1', '', 'gcr.io/test/cloud-tunnel-client:split-v1'),
            ('registry.example/custom/tunnel:v1', '', 'registry.example/custom/tunnel:v1'),
            ('split-v1', 'customer.example/vdc', 'customer.example/vdc/cloud-tunnel-client:split-v1'),
            ('registry.example/custom/tunnel:v1', 'customer.example/vdc', 'customer.example/vdc/cloud-tunnel-client:v1'),
            ('registry.example/custom/tunnel@sha256:abc', 'customer.example/vdc', 'customer.example/vdc/cloud-tunnel-client@sha256:abc'),
        ]
        for image, repository, expected in cases:
            with self.subTest(image=image, repository=repository), tempfile.TemporaryDirectory() as directory:
                agent_repo = f'{repository}/cloud-agent' if repository else 'gcr.io/test/cloud-agent'
                config = 'locals {\n' + expressions + '\n' + (
                    f'api_config = {{ tunnel_client_image_url = {json.dumps(image)} }}\n'
                    f'image_repo_url = {json.dumps(repository)}\n'
                    f'agent_image_repository = {json.dumps(agent_repo)}\n' + '}\n'
                )
                pathlib.Path(directory, 'main.tf').write_text(config)
                result = subprocess.run(['terraform', 'console'], cwd=directory,
                                        input='jsonencode(local.tunnel_client_image)\n',
                                        text=True, capture_output=True, check=True)
                self.assertEqual(json.loads(json.loads(result.stdout)), expected)

    def test_uploaded_archive_matches_sources_and_renders(self):
        expected = {p.relative_to(CHART).as_posix(): p.read_bytes() for p in CHART.rglob('*')
                    if p.is_file() and (p.name in ['Chart.yaml', 'values.yaml'] or p.parent.name == 'templates')}
        with zipfile.ZipFile(CHART.parent / 'agent-context.zip') as archive:
            self.assertEqual(set(archive.namelist()), set(expected))
            for name, content in expected.items():
                self.assertEqual(archive.read(name), content, name)
            with tempfile.TemporaryDirectory() as directory:
                archive.extractall(directory)
                image = 'registry.example/cloud-tunnel-client:test'
                self.assertEqual(render(directory, image), render(CHART, image))


if __name__ == '__main__':
    unittest.main()
