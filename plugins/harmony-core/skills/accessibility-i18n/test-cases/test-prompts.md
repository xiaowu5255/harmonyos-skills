# 测试提示词 — accessibility-i18n

> 种子用例,取自仓库级回归集 `tools/evals/evals.json`。可按需补充边界条件 / 错误处理场景。

## 基础功能测试

### 场景 1
**提示词**：鸿蒙应用上架被驳回,说无障碍不合规,按钮没有可读标签,怎么改?

**预期输出**：触发 accessibility-i18n;给出 accessibilityText 标注 + accessibilityLevel('yes') 方案;装饰性元素设 'no' + 卡片用 accessibilityGroup

### 场景 2
**提示词**：App 要出海,支持英文和阿拉伯语,日期和数字格式要跟着语言变,怎么做?

**预期输出**：触发 accessibility-i18n;给出 base→en_US→ar 资源文件组织 + Intl.DateTimeFormat/Intl.NumberFormat + Direction.Auto RTL 适配

### 场景 3
**提示词**：鸿蒙应用设置了多语言 resource,但切换到英文后有些文字还是中文,哪里不对?

**预期输出**：触发 accessibility-i18n;定位硬编码字符串;全局搜索 fontSize()/fontColor() 等找出未用 $r() 的文本;base/ 必须有全部 key 作为回退
