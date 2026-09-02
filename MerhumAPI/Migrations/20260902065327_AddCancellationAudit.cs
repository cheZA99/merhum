using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MerhumAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddCancellationAudit : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CancellationReason",
                table: "ServiceOrders",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CancelledAt",
                table: "ServiceOrders",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CancelledByUserId",
                table: "ServiceOrders",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CancellationReason",
                table: "Appointments",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CancelledAt",
                table: "Appointments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CancelledByUserId",
                table: "Appointments",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_ServiceOrders_CancelledByUserId",
                table: "ServiceOrders",
                column: "CancelledByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Appointments_CancelledByUserId",
                table: "Appointments",
                column: "CancelledByUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Appointments_AspNetUsers_CancelledByUserId",
                table: "Appointments",
                column: "CancelledByUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ServiceOrders_AspNetUsers_CancelledByUserId",
                table: "ServiceOrders",
                column: "CancelledByUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Appointments_AspNetUsers_CancelledByUserId",
                table: "Appointments");

            migrationBuilder.DropForeignKey(
                name: "FK_ServiceOrders_AspNetUsers_CancelledByUserId",
                table: "ServiceOrders");

            migrationBuilder.DropIndex(
                name: "IX_ServiceOrders_CancelledByUserId",
                table: "ServiceOrders");

            migrationBuilder.DropIndex(
                name: "IX_Appointments_CancelledByUserId",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "CancellationReason",
                table: "ServiceOrders");

            migrationBuilder.DropColumn(
                name: "CancelledAt",
                table: "ServiceOrders");

            migrationBuilder.DropColumn(
                name: "CancelledByUserId",
                table: "ServiceOrders");

            migrationBuilder.DropColumn(
                name: "CancellationReason",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "CancelledAt",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "CancelledByUserId",
                table: "Appointments");
        }
    }
}
