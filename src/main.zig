const std = @import("std");

const Node = union(enum) {
    Statement: Statement,
    Expression: Expression,
};

const Statement = union(enum) {
    expression_statement: ?*ExpressionStatement,
    // Imagine that their is a few more statements
    // in this small case example this isn't needed

    pub fn format(self: Statement, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            inline else => |statement| {
                if (statement) |stmt| try stmt.format(fmt, options, writer);
            },
        }
    }

    pub fn downcast(self: Statement, comptime T: type) ?*T {
        inline for (@typeInfo(Statement).Union.fields) |field| {
            if (field.type == ?*T) {
                return @field(self, field.name);
            }
        }
        return null;
    }
};

const ExpressionStatement = struct {
    expression: Expression,

    pub fn format(self: ExpressionStatement, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{}", .{self.expression});
    }
};

const Expression = union(enum) {
    // Nullable pointer because the UnaryExpression contains an Expression
    // so we must be able to know about its size at compile time
    unary: ?*UnaryExpression,
    number: ?*NumberLiteralExpression,

    pub fn format(self: Expression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            inline else => |expression| {
                if (expression) |expr| try expr.format(fmt, options, writer);
            },
        }
    }

    pub fn downcast(self: Expression, comptime T: type) ?*T {
        inline for (@typeInfo(Expression).Union.fields) |field| {
            if (field.type == ?*T) {
                return @field(self, field.name);
            }
        }
        return null;
    }
};

const UnaryExpression = struct {
    // The operator in the real case is a Token, simplified to a u8 here
    operator: u8,
    right: Expression,

    pub fn format(self: UnaryExpression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{c}{}", .{ self.operator, self.right });
    }
};

const NumberLiteralExpression = struct {
    value: i32,

    pub fn format(self: NumberLiteralExpression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{d}", .{self.value});
    }
};

pub fn main() !void {
    var number_literal_expression = NumberLiteralExpression{ .value = 10 };
    var unary_expression = UnaryExpression{ .operator = '-', .right = .{ .number = &number_literal_expression } };
    var expression_statement = ExpressionStatement{ .expression = .{ .unary = &unary_expression } };
    var statement = Statement{ .expression_statement = &expression_statement };

    std.debug.print("statement: {}\n", .{statement});

    // ✅ Downcast from Statement to ExpressionStatement
    if (statement.downcast(ExpressionStatement)) |expr_stmt| {
        // ✅ Downcast from ExpressionStatement.Expression to UnaryExpression
        if (expr_stmt.expression.downcast(UnaryExpression)) |unary| {
            // ❌ Downcast from UnaryExpression.Right to NumberLiteralExpression
            if (unary.right.downcast(NumberLiteralExpression)) |number| {
                std.debug.print("I am a NumberLiteralExpression and not a UnaryExpression: {}\n", .{number});
            }
        }
    }
}
