---
name: antd-patterns
description: Ant Design React UI patterns, enterprise components, theming, and professional interface development
---

# Ant Design Development Patterns

## When to Use This Skill

- Building enterprise React applications
- Implementing professional UI components
- Creating admin dashboards
- Following Ant Design best practices

## Target Agents

- `antd-ui-developer` - Primary user
- `react-typescript-expert` - Type-safe Ant Design
- `frontend-developer` - Enterprise UI development

## Core Patterns

### 1. Form Patterns

```tsx
import { Form, Input, Button } from 'antd'

const UserForm = () => {
  const [form] = Form.useForm()

  const onFinish = (values: any) => {
    console.log('Success:', values)
  }

  return (
    <Form
      form={form}
      layout="vertical"
      onFinish={onFinish}
      initialValues={{ remember: true }}
    >
      <Form.Item
        label="Email"
        name="email"
        rules={[
          { required: true, message: 'Please input your email!' },
          { type: 'email', message: 'Invalid email format!' }
        ]}
      >
        <Input />
      </Form.Item>

      <Form.Item>
        <Button type="primary" htmlType="submit">
          Submit
        </Button>
      </Form.Item>
    </Form>
  )
}
```

### 2. Table with Actions

```tsx
import { Table, Space, Button } from 'antd'

const UserTable = () => {
  const columns = [
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      sorter: (a, b) => a.name.localeCompare(b.name),
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_, record) => (
        <Space>
          <Button type="link">Edit</Button>
          <Button type="link" danger>Delete</Button>
        </Space>
      ),
    },
  ]

  return <Table columns={columns} dataSource={data} />
}
```

### 3. Custom Theme

```tsx
import { ConfigProvider, theme } from 'antd'

<ConfigProvider
  theme={{
    token: {
      colorPrimary: '#00b96b',
      borderRadius: 8,
    },
    algorithm: theme.darkAlgorithm,
  }}
>
  <App />
</ConfigProvider>
```

## Best Practices

1. Use **Form.useForm()** hook
2. Implement **TypeScript** types
3. Leverage **ConfigProvider** for theming
4. Use **message/notification** for feedback
5. Follow Ant Design **guidelines**
