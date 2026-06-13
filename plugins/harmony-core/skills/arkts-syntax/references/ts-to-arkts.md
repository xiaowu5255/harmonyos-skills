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
7. JSON / 动态数据边界范式(强类型场景)
8. 动态数组与未知数据的类型窄化
9. 硬禁清单(快速对照)

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

## 3. 字段初始化(强制 TS 严格检查 strictPropertyInitialization,错误码 10605999)

> 注:无独立 `arkts-*` 规则名;ArkTS 通过强制开启 TS 严格类型检查实施。用确定赋值
> 断言 `!`(`name!: string`)可消除报错,但会触发 `warning: arkts-no-definite-assignment`,
> 官方不推荐。

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

## 5. 解构与展开(arkts-no-destruct-assignment / -decls / -params / -spread)

**解构是错误级禁止,不是"部分受限"**:解构赋值(`arkts-no-destruct-assignment`,10605069)、
解构变量声明(`arkts-no-destruct-decls`,10605074)、参数解构(`arkts-no-destruct-params`,
10605091)一律报错。展开运算符(`arkts-no-spread`,10605099)**仅**支持数组/Array 子类/
TypedArray 在两个场景:传给剩余参数、复制到数组字面量;**对象展开 `{...obj}` 禁止**。

```typescript
// 错误:解构变量声明与解构赋值均禁止
const { width, height } = getSize();

// 正确:显式访问
const size = getSize();
const width = size.width;
const height = size.height;

// 数组展开到剩余参数 / 数组字面量 → 允许
fn(...arr);  const copy = [...arr];
// 对象展开 → 禁止,改用逐字段赋值或 Object 构造
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

## 7. JSON / 动态数据边界范式(强类型场景)

> 第 1 节给了"定义类型 + 受控转换"的基线写法。对**类型纪律要求最高的场景**(纯函数 / 工具
> 库 / L0 任务,或团队禁用 `any`/`Record` 碳载体时),用下面更严格的"命名模型 + 一次性强转 +
> 逐字段拷贝"范式,从源头杜绝运行时属性探测。

**核心规则**:把 `JSON.parse`、Preferences、router 参数、AppStorage、SDK 回调返回值都当成
**不透明数据**,先 `typeof`/判空归一,再拷进严格模型;**绝不在动态对象上做字段探测**。

```typescript
// 已知顶层字段:定义命名 raw 模型,一次性强转,再校验+拷贝进严格结果模型
interface TaskRawInput { title?: string; count?: number; }
const input = JSON.parse(raw) as TaskRawInput;
const title: string = typeof input.title === 'string' ? input.title : '';
const count: number = typeof input.count === 'number' ? input.count : 0;
```

**禁止的探测手段**(都属于动态反射,ArkTS 不接受 / 强类型纪律下禁用):

| 禁用写法 | 替代 |
|---|---|
| `'field' in data` | 强转命名模型后直接读字段并判空 |
| `data[key]` / `obj[key]` 动态键访问 | 命名字段;任意键集合用 `Map<string, T>` |
| `Reflect.get(obj, k)` / `Object.keys(obj)` 配下标 | 同上;需遍历键值改用 `Map` |
| `hasOwnProperty` / getter 探针 | 强转模型 + `typeof`/`null` 校验 |
| 内联结构类型转换 `(data as { labels?: Object }).labels` | 顶层定义命名 interface,只转一次 |
| 把解析结果转成 `JSON`/`Map`/函数/匿名结构 | 转命名 raw 模型 |

> 对**任意键**的 map、别名表、嵌套树:不要做运行时对象字段探测,写一个**任务专用的小型
> 字符串扫描器**直接填充 `Map`/数组,比探测动态对象更符合 ArkTS 静态约束。

## 8. 动态数组与未知数据的类型窄化

JSON / 动态边界上**不要依赖推断类型**,显式声明 `Object | null` 再逐元素 `typeof` 校验:

```typescript
// 正确:动态数组的安全窄化
const rawItems: Object | null = input.items ?? null;
const out: Array<number> = [];
if (Array.isArray(rawItems)) {
  for (let i = 0; i < rawItems.length; i++) {
    const item: Object = rawItems[i];           // 元素先按 Object 取
    if (typeof item === 'number') { out.push(item); }  // 校验后才放进强类型数组
  }
}
```

**铁律**:
- 不要写类型谓词助手 `value is number`,也不要指望布尔助手调用能窄化类型。
- 不要把 `Object` 或 `Object | null` 直接赋给强类型数组或模型字段——只拷贝**校验过的元素**。
- 可选数字进运算前先归一(`?? 0`),避免 `undefined` 参与算术。

## 9. 硬禁清单(快速对照)

以下在 ArkTS 严格模式下一律禁止 / 强烈不建议,遇到先重写成合规形式(具体规则名与是否报错
**以本机编译器输出为准**,见本文件顶部说明):

| 类别 | 禁用 | 合规替代 |
|---|---|---|
| 顶层类型 | `any` / `unknown` / `ESObject` | 命名 class/interface;不透明数据用 `Object` + 校验 |
| 碳载体 | 用 `object` / 宽 `Record<string,…>` 当万能容器 | 命名模型;任意键用 `Map` |
| 类型运算 | `ReturnType`/`Partial`/`Pick`/`Omit`/`Parameters` 等 TS 工具类型 | 显式写出目标类型 |
| 类型位置 | 类型位 `typeof`、类型谓词 `x is T`、非空断言 `!` | 显式类型标注 + 运行时校验 |
| 异常 | 带类型的 `catch (e: Error)` | `catch (e)` 后自行 `instanceof`/`typeof` 判定 |
| 模块 | `require(...)`、动态/类型 `import(...)` | 顶部静态 `import` |
| 声明 | `var`、解构声明/赋值/参数、函数/类表达式、生成器 | `let`/`const`、显式访问、具名函数/类 |
| 动态对象 | `delete`、`in`、`for..in`、`obj[key]`、原型/`globalThis` 改写 | `Map`;`for..of`/索引遍历 |
| 反射调用 | `Reflect.get`、`hasOwnProperty`、`.call`/`.apply`、`Object.entries` 探测 | 命名字段;`Map` 遍历;箭头函数绑定 |
| 字面量 | `as const`、`new.target`、构造参数字段简写 | 显式常量/字段声明 |

> 注:本表条目源自对 ArkTS 严格规则包的归纳,作为"写之前默念"的对照表。若某条与你工程的
> 编译器版本实际行为不符,以编译器为准,并通过 `/harmony-feedback` 回流修正本表。

---

## 维护说明

新增条目时保持"规则名 → 场景 → 改写"三段结构,并在改写代码上标注验证过的
API 版本。来源于真实项目报错的条目优先级最高。
