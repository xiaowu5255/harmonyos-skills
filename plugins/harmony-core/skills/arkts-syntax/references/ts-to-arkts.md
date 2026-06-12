# TypeScript → ArkTS 迁移参考(种子版 v0.1.0)

> 本文件是按需加载的深度参考。条目格式固定为:规则名 → 报错场景 → 改写示例。
> 这是种子版本,通过 `/harmony-feedback` 回流的真实案例会持续扩充本表。
> 注意:具体规则名以项目实际编译器输出为准;如发现本表与编译器行为不符,以编译器为准并提交反馈。

## 目录
1. any/unknown 类型
2. 动态属性操作
3. 字段初始化
4. 结构化类型
5. 解构与展开
6. 其他高频限制

---

## 1. any/unknown 类型(arkts-no-any-unknown)

**报错场景**:`let data: any = JSON.parse(text)`

**改写**:
```typescript
// 错误
let data: any = JSON.parse(text);

// 正确:定义类型后做受控转换
interface UserInfo {
  name: string;
  age: number;
}
let data: UserInfo = JSON.parse(text) as UserInfo;
```
对结构不完全可知的数据,用 `Record<string, Object>` 或逐字段校验,不要退回 any。

## 2. 动态属性操作(对象布局不可变)

**报错场景**:`obj.newProp = 1`(newProp 未在类型中声明)、`delete obj.prop`

**改写**:
```typescript
// 错误
let config: Config = getConfig();
config.extra = 'x';      // 动态加属性
delete config.timeout;   // 删属性

// 正确:需要动态键值时改用 Map
let config: Map<string, string> = new Map();
config.set('extra', 'x');
config.delete('timeout');
```

## 3. 字段初始化(arkts-strict-property-initialization)

```typescript
// 错误
class Profile {
  name: string;          // 未初始化
}

// 正确(三选一)
class Profile {
  name: string = '';     // 默认值
  nick?: string;         // 可选
  id: string;
  constructor(id: string) { this.id = id; }  // 构造函数初始化
}
```

## 4. 结构化类型限制

```typescript
// 错误:形状相同 ≠ 类型兼容
class A { v: number = 0 }
class B { v: number = 0 }
let a: A = new B();   // ArkTS 拒绝

// 正确:显式建立类型关系
interface HasV { v: number }
class A implements HasV { v: number = 0 }
class B implements HasV { v: number = 0 }
let x: HasV = new B();
```

## 5. 解构与展开

部分解构/展开写法受限。保险写法是显式访问:

```typescript
// 可能受限(视编译器版本)
const { width, height } = getSize();

// 永远安全
const size = getSize();
const width = size.width;
const height = size.height;
```

## 6. 其他高频限制

| 限制 | 替代方案 |
|---|---|
| `var` 声明 | `let` / `const` |
| `#private` 字段 | `private` 关键字 |
| `Function.apply` / 动态 this | 箭头函数 / 显式绑定的方法 |
| 原型链运行时修改 | 类继承 |
| 索引签名访问普通对象 | `Map` 或定义明确的 `Record` 类型 |
| 标签语句、with、eval | 重构控制流;ArkTS 一律禁止 |

---

## 维护说明

新增条目时保持"规则名 → 场景 → 改写"三段结构,并在改写代码上标注验证过的
API 版本。来源于真实项目报错的条目优先级最高。
