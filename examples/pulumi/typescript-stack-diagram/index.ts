import * as aws from "@pulumi/aws";
import * as plotwork from "@pulumi/plotwork";
import * as pulumi from "@pulumi/pulumi";

const config = new pulumi.Config();
const environment = config.get("environment") ?? pulumi.getStack();
const replicas = config.getNumber("replicas") ?? 2;
// Set to publish to an organisation's private library instead of your own.
const organization = config.get("organization");
// Set to also write the SVG to this S3 bucket. Rendering needs the Pro plan.
const bucket = config.get("bucket");

// Stands in for the real stack, so the example runs with no cloud account.
// In your program, use your resources' outputs instead: vpc.cidrBlock,
// lb.dnsName, db.address, and so on.
const deployment = pulumi.output({
  vpcCidr: "10.20.0.0/16",
  subnets: { "app-a": "10.20.10.0/24", "app-b": "10.20.11.0/24" } as Record<string, string>,
  lbDnsName: "shop-web-1234567890.ap-southeast-2.elb.amazonaws.com",
  dbEndpoint: "shop-db.abcdefghij.ap-southeast-2.rds.amazonaws.com",
  replicas,
});

// The diagram is built from the stack's outputs, so Pulumi publishes it again
// whenever one of them changes.
const source = deployment.apply((d) => {
  const subnets = Object.entries(d.subnets).map(([name, cidr]) => ({ id: name.replace(/-/g, "_"), name, cidr }));
  return [
    `flow "${environment} network" desc="Traffic from users to the ${environment} application, drawn from the stack's outputs."`,
    "",
    'node users person "Users"',
    `node lb gateway "Load balancer" sub="${d.lbDnsName}"`,
    "",
    `group vpc "VPC ${d.vpcCidr}" type=network {`,
    ...subnets.map((s) => `  node ${s.id} service "${s.name}" sub="${s.cidr}, ${d.replicas} tasks"`),
    `  node db database "PostgreSQL" sub="${d.dbEndpoint}"`,
    "}",
    "",
    'users -> lb : "HTTPS"',
    ...subnets.flatMap((s) => [`lb -> ${s.id} : "routes"`, `${s.id} -> db : "queries" role=data`]),
    "",
  ].join("\n");
});

const diagram = new plotwork.Diagram("network", {
  source,
  name: `${environment} network`,
  folder: "Examples/Pulumi",
  scheme: "auto",
  // A stable link is for a personal library; an organisation's diagram has a view link instead.
  ...(organization === undefined ? { alias: `network-${environment}` } : { organization, classification: "internal" }),
});

// The link to share: the stable link of a personal diagram, or the portal page
// an organisation's members open.
export const link = organization === undefined ? diagram.stableUrl : diagram.viewUrl;

// Renders the same source to an SVG and keeps it in your own bucket.
function writeSvg(bucketName: string): pulumi.Output<string> {
  const picture = plotwork.getRenderOutput({ source, scheme: "auto" });
  const object = new aws.s3.BucketObjectv2("network-svg", {
    bucket: bucketName,
    key: `diagrams/${environment}-network.svg`,
    content: picture.svg,
    contentType: "image/svg+xml",
  });
  return object.key;
}

export const svgKey = bucket === undefined ? null : writeSvg(bucket);
